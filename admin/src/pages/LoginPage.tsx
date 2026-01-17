import { Lock as LockIcon } from '@mui/icons-material';
import {
    Alert,
    Box,
    Button,
    Card,
    CardContent,
    CircularProgress,
    Container,
    TextField,
    Typography,
} from '@mui/material';
import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';

export default function LoginPage() {
    const [otp, setOtp] = useState('');
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);
    const { login } = useAuth();
    const navigate = useNavigate();

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!otp.trim()) {
            setError('Please enter the OTP');
            return;
        }

        setLoading(true);
        setError('');

        try {
            const success = await login(otp.trim());
            if (success) {
                navigate('/');
            } else {
                setError('Invalid OTP. Please try again.');
            }
        } catch {
            setError('Failed to authenticate. Please try again.');
        } finally {
            setLoading(false);
        }
    };

    return (
        <Box
            sx={{
                minHeight: '100vh',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
            }}
        >
            <Container maxWidth="sm">
                <Card sx={{ p: 2 }}>
                    <CardContent>
                        <Box sx={{ textAlign: 'center', mb: 4 }}>
                            <Box
                                sx={{
                                    width: 64,
                                    height: 64,
                                    borderRadius: '50%',
                                    bgcolor: 'primary.main',
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'center',
                                    mx: 'auto',
                                    mb: 2,
                                }}
                            >
                                <LockIcon sx={{ fontSize: 32, color: 'white' }} />
                            </Box>
                            <Typography variant="h4" gutterBottom>
                                Admin Login
                            </Typography>
                            <Typography color="text.secondary">
                                Enter your OTP to access the admin panel
                            </Typography>
                        </Box>

                        {error && (
                            <Alert severity="error" sx={{ mb: 3 }}>
                                {error}
                            </Alert>
                        )}

                        <form onSubmit={handleSubmit}>
                            <TextField
                                fullWidth
                                label="OTP"
                                type="password"
                                value={otp}
                                onChange={(e) => setOtp(e.target.value)}
                                placeholder="Enter your OTP"
                                autoFocus
                                sx={{ mb: 3 }}
                            />

                            <Button
                                fullWidth
                                type="submit"
                                variant="contained"
                                size="large"
                                disabled={loading}
                                sx={{ py: 1.5 }}
                            >
                                {loading ? (
                                    <CircularProgress size={24} color="inherit" />
                                ) : (
                                    'Login'
                                )}
                            </Button>
                        </form>
                    </CardContent>
                </Card>
            </Container>
        </Box>
    );
}
