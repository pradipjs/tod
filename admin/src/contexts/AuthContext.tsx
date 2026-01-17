import { createContext, type ReactNode, useCallback, useContext, useEffect, useState } from 'react';
import { clearAuthToken, getAuthToken, setAuthToken, verifyAuth } from '../api';

interface AuthContextType {
    isAuthenticated: boolean;
    isLoading: boolean;
    login: (otp: string) => Promise<boolean>;
    logout: () => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider = ({ children }: { children: ReactNode }) => {
    const [isAuthenticated, setIsAuthenticated] = useState(false);
    const [isLoading, setIsLoading] = useState(true);

    // Check auth on mount
    useEffect(() => {
        const checkAuth = async () => {
            const token = getAuthToken();
            if (token) {
                const valid = await verifyAuth();
                setIsAuthenticated(valid);
                if (!valid) {
                    clearAuthToken();
                }
            }
            setIsLoading(false);
        };
        checkAuth();
    }, []);

    const login = useCallback(async (otp: string): Promise<boolean> => {
        setAuthToken(otp);
        const valid = await verifyAuth();
        setIsAuthenticated(valid);
        if (!valid) {
            clearAuthToken();
        }
        return valid;
    }, []);

    const logout = useCallback(() => {
        clearAuthToken();
        setIsAuthenticated(false);
    }, []);

    return (
        <AuthContext.Provider value={{ isAuthenticated, isLoading, login, logout }}>
            {children}
        </AuthContext.Provider>
    );
};

export const useAuth = () => {
    const context = useContext(AuthContext);
    if (context === undefined) {
        throw new Error('useAuth must be used within an AuthProvider');
    }
    return context;
};
