import { Box, Button, Card, CardContent, Typography } from '@mui/material';
import { Component, type ErrorInfo, type ReactNode } from 'react';

interface Props {
    children: ReactNode;
    fallback?: ReactNode;
}

interface State {
    hasError: boolean;
    error: Error | null;
    errorInfo: ErrorInfo | null;
}

export default class ErrorBoundary extends Component<Props, State> {
    constructor(props: Props) {
        super(props);
        this.state = {
            hasError: false,
            error: null,
            errorInfo: null,
        };
    }

    static getDerivedStateFromError(error: Error): Partial<State> {
        return { hasError: true, error };
    }

    componentDidCatch(error: Error, errorInfo: ErrorInfo): void {
        // Log error to console in development
        console.error('ErrorBoundary caught an error:', error, errorInfo);

        this.setState({
            error,
            errorInfo,
        });

        // In production, you might want to send this to an error tracking service
        // Example: Sentry.captureException(error);
    }

    handleReset = (): void => {
        this.setState({
            hasError: false,
            error: null,
            errorInfo: null,
        });
    };

    handleReload = (): void => {
        window.location.reload();
    };

    render(): ReactNode {
        if (this.state.hasError) {
            // Custom fallback UI if provided
            if (this.props.fallback) {
                return this.props.fallback;
            }

            // Default error UI
            return (
                <Box
                    sx={{
                        display: 'flex',
                        flexDirection: 'column',
                        alignItems: 'center',
                        justifyContent: 'center',
                        minHeight: '50vh',
                        p: 3,
                    }}
                >
                    <Card sx={{ maxWidth: 500, width: '100%' }}>
                        <CardContent>
                            <Typography variant="h5" color="error" gutterBottom>
                                Something went wrong
                            </Typography>
                            <Typography color="text.secondary" sx={{ mb: 2 }}>
                                We're sorry, but something unexpected happened. Please try again.
                            </Typography>

                            {/* Show error details in development */}
                            {import.meta.env.DEV && this.state.error && (
                                <Box
                                    sx={{
                                        p: 2,
                                        mb: 2,
                                        bgcolor: 'grey.100',
                                        borderRadius: 1,
                                        overflow: 'auto',
                                        maxHeight: 200,
                                    }}
                                >
                                    <Typography
                                        variant="body2"
                                        component="pre"
                                        sx={{ fontFamily: 'monospace', fontSize: '0.75rem', m: 0 }}
                                    >
                                        {this.state.error.toString()}
                                        {this.state.errorInfo?.componentStack}
                                    </Typography>
                                </Box>
                            )}

                            <Box sx={{ display: 'flex', gap: 2 }}>
                                <Button
                                    variant="contained"
                                    onClick={this.handleReset}
                                    color="primary"
                                >
                                    Try Again
                                </Button>
                                <Button
                                    variant="outlined"
                                    onClick={this.handleReload}
                                >
                                    Reload Page
                                </Button>
                            </Box>
                        </CardContent>
                    </Card>
                </Box>
            );
        }

        return this.props.children;
    }
}
