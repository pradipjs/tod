import {
    CheckCircle as ActiveIcon,
    Category as CategoryIcon,
    Assignment as TaskIcon,
} from '@mui/icons-material';
import {
    Box,
    Card,
    CardActionArea,
    CardContent,
    CircularProgress,
    Grid,
    Typography,
} from '@mui/material';
import { useQuery } from '@tanstack/react-query';
import { useNavigate } from 'react-router-dom';
import { getCategoryCount, getTaskCount } from '../api';

export default function DashboardPage() {
    const navigate = useNavigate();

    // Use count APIs instead of fetching all data
    const { data: totalCategories, isLoading: loadingTotalCategories } = useQuery({
        queryKey: ['categories', 'count', 'total'],
        queryFn: () => getCategoryCount(),
    });

    const { data: activeCategories, isLoading: loadingActiveCategories } = useQuery({
        queryKey: ['categories', 'count', 'active'],
        queryFn: () => getCategoryCount({ active: true }),
    });

    const { data: totalTasks, isLoading: loadingTotalTasks } = useQuery({
        queryKey: ['tasks', 'count', 'total'],
        queryFn: () => getTaskCount(),
    });

    // Task counts by type
    const { data: truthCount, isLoading: loadingTruthCount } = useQuery({
        queryKey: ['tasks', 'count', 'truth'],
        queryFn: () => getTaskCount({ types: ['truth'] }),
    });

    const { data: dareCount, isLoading: loadingDareCount } = useQuery({
        queryKey: ['tasks', 'count', 'dare'],
        queryFn: () => getTaskCount({ types: ['dare'] }),
    });

    const isLoading = loadingTotalCategories || loadingActiveCategories || loadingTotalTasks ||
        loadingTruthCount || loadingDareCount;

    const stats = [
        {
            title: 'Total Categories',
            value: totalCategories ?? 0,
            icon: <CategoryIcon sx={{ fontSize: 28 }} />,
            color: '#6366f1',
            onClick: () => navigate('/categories'),
        },
        {
            title: 'Active Categories',
            value: activeCategories ?? 0,
            icon: <ActiveIcon sx={{ fontSize: 28 }} />,
            color: '#10b981',
            onClick: () => navigate('/categories?active=true'),
        },
        {
            title: 'Total Tasks',
            value: totalTasks ?? 0,
            icon: <TaskIcon sx={{ fontSize: 28 }} />,
            color: '#ec4899',
            onClick: () => navigate('/tasks'),
        },
        {
            title: 'Truths',
            value: truthCount ?? 0,
            icon: <TaskIcon sx={{ fontSize: 28 }} />,
            color: '#f59e0b',
            onClick: () => navigate('/tasks?type=truth'),
        },
    ];

    if (isLoading) {
        return (
            <Box
                sx={{
                    display: 'flex',
                    justifyContent: 'center',
                    alignItems: 'center',
                    height: '50vh',
                }}
            >
                <CircularProgress />
            </Box>
        );
    }

    return (
        <Box>
            <Typography variant="h5" fontWeight={700} sx={{ mb: 2 }}>
                Dashboard
            </Typography>

            <Grid container spacing={2}>
                {stats.map((stat) => (
                    <Grid size={{ xs: 6, sm: 3 }} key={stat.title}>
                        <Card sx={{ cursor: 'pointer', '&:hover': { boxShadow: 4 } }}>
                            <CardActionArea onClick={stat.onClick}>
                                <CardContent sx={{ py: 1.5, px: 2, '&:last-child': { pb: 1.5 } }}>
                                    <Box
                                        sx={{
                                            display: 'flex',
                                            alignItems: 'center',
                                            justifyContent: 'space-between',
                                        }}
                                    >
                                        <Box>
                                            <Typography
                                                color="text.secondary"
                                                variant="caption"
                                            >
                                                {stat.title}
                                            </Typography>
                                            <Typography variant="h4" fontWeight={700}>
                                                {stat.value}
                                            </Typography>
                                        </Box>
                                        <Box
                                            sx={{
                                                color: stat.color,
                                                opacity: 0.8,
                                            }}
                                        >
                                            {stat.icon}
                                        </Box>
                                    </Box>
                                </CardContent>
                            </CardActionArea>
                        </Card>
                    </Grid>
                ))}
            </Grid>

            <Grid container spacing={2} sx={{ mt: 1 }}>
                <Grid size={{ xs: 12, md: 6 }}>
                    <Card sx={{ cursor: 'pointer', '&:hover': { boxShadow: 4 } }}>
                        <CardActionArea onClick={() => navigate('/tasks')}>
                            <CardContent sx={{ py: 1.5, px: 2, '&:last-child': { pb: 1.5 } }}>
                                <Typography variant="subtitle2" fontWeight={600}>
                                    Tasks by Type
                                </Typography>
                                <Box sx={{ display: 'flex', gap: 4, mt: 1 }}>
                                    <Box>
                                        <Typography variant="h5" color="primary" fontWeight={700}>
                                            {truthCount ?? 0}
                                        </Typography>
                                        <Typography variant="caption" color="text.secondary">Truths</Typography>
                                    </Box>
                                    <Box>
                                        <Typography variant="h5" color="secondary" fontWeight={700}>
                                            {dareCount ?? 0}
                                        </Typography>
                                        <Typography variant="caption" color="text.secondary">Dares</Typography>
                                    </Box>
                                </Box>
                            </CardContent>
                        </CardActionArea>
                    </Card>
                </Grid>

                <Grid size={{ xs: 12, md: 6 }}>
                    <Card sx={{ cursor: 'pointer', '&:hover': { boxShadow: 4 } }}>
                        <CardActionArea onClick={() => navigate('/categories')}>
                            <CardContent sx={{ py: 1.5, px: 2, '&:last-child': { pb: 1.5 } }}>
                                <Typography variant="subtitle2" fontWeight={600}>
                                    Quick Stats
                                </Typography>
                                <Box sx={{ display: 'flex', gap: 4, mt: 1 }}>
                                    <Box>
                                        <Typography variant="h5" color="success.main" fontWeight={700}>
                                            {activeCategories ?? 0}
                                        </Typography>
                                        <Typography variant="caption" color="text.secondary">Active Categories</Typography>
                                    </Box>
                                    <Box>
                                        <Typography variant="h5" color="warning.main" fontWeight={700}>
                                            {totalTasks ?? 0}
                                        </Typography>
                                        <Typography variant="caption" color="text.secondary">Total Tasks</Typography>
                                    </Box>
                                </Box>
                            </CardContent>
                        </CardActionArea>
                    </Card>
                </Grid>
            </Grid>
        </Box>
    );
}
