import {
    CheckCircle as ActiveIcon,
    Category as CategoryIcon,
    Block as InactiveIcon,
    Assignment as TaskIcon,
} from '@mui/icons-material';
import {
    Box,
    Card,
    CardContent,
    CircularProgress,
    Grid,
    Typography,
} from '@mui/material';
import { useQuery } from '@tanstack/react-query';
import { getCategoryCount, getTaskCount } from '../api';

export default function DashboardPage() {
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

    const { data: inactiveTasks, isLoading: loadingInactiveTasks } = useQuery({
        queryKey: ['tasks', 'count', 'inactive'],
        queryFn: () => getTaskCount({ active: false }),
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
        loadingInactiveTasks || loadingTruthCount || loadingDareCount;

    const stats = [
        {
            title: 'Total Categories',
            value: totalCategories ?? 0,
            icon: <CategoryIcon sx={{ fontSize: 40 }} />,
            color: '#6366f1',
        },
        {
            title: 'Active Categories',
            value: activeCategories ?? 0,
            icon: <ActiveIcon sx={{ fontSize: 40 }} />,
            color: '#10b981',
        },
        {
            title: 'Total Tasks',
            value: totalTasks ?? 0,
            icon: <TaskIcon sx={{ fontSize: 40 }} />,
            color: '#ec4899',
        },
        {
            title: 'Inactive Tasks',
            value: inactiveTasks ?? 0,
            icon: <InactiveIcon sx={{ fontSize: 40 }} />,
            color: '#f59e0b',
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
            <Typography variant="h4" gutterBottom fontWeight={700}>
                Dashboard
            </Typography>
            <Typography color="text.secondary" sx={{ mb: 4 }}>
                Overview of your Truth or Dare content
            </Typography>

            <Grid container spacing={3}>
                {stats.map((stat) => (
                    <Grid size={{ xs: 12, sm: 6, md: 3 }} key={stat.title}>
                        <Card>
                            <CardContent>
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
                                            variant="body2"
                                            gutterBottom
                                        >
                                            {stat.title}
                                        </Typography>
                                        <Typography variant="h3" fontWeight={700}>
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
                        </Card>
                    </Grid>
                ))}
            </Grid>

            <Grid container spacing={3} sx={{ mt: 2 }}>
                <Grid size={{ xs: 12, md: 6 }}>
                    <Card>
                        <CardContent>
                            <Typography variant="h6" gutterBottom fontWeight={600}>
                                Tasks by Type
                            </Typography>
                            <Box sx={{ display: 'flex', gap: 4, mt: 2 }}>
                                <Box>
                                    <Typography variant="h4" color="primary" fontWeight={700}>
                                        {truthCount ?? 0}
                                    </Typography>
                                    <Typography color="text.secondary">Truths</Typography>
                                </Box>
                                <Box>
                                    <Typography variant="h4" color="secondary" fontWeight={700}>
                                        {dareCount ?? 0}
                                    </Typography>
                                    <Typography color="text.secondary">Dares</Typography>
                                </Box>
                            </Box>
                        </CardContent>
                    </Card>
                </Grid>

                <Grid size={{ xs: 12, md: 6 }}>
                    <Card>
                        <CardContent>
                            <Typography variant="h6" gutterBottom fontWeight={600}>
                                Quick Stats
                            </Typography>
                            <Box sx={{ display: 'flex', gap: 4, mt: 2 }}>
                                <Box>
                                    <Typography variant="h4" color="success.main" fontWeight={700}>
                                        {activeCategories ?? 0}
                                    </Typography>
                                    <Typography color="text.secondary">Active Categories</Typography>
                                </Box>
                                <Box>
                                    <Typography variant="h4" color="warning.main" fontWeight={700}>
                                        {(totalTasks ?? 0) - (inactiveTasks ?? 0)}
                                    </Typography>
                                    <Typography color="text.secondary">Active Tasks</Typography>
                                </Box>
                            </Box>
                        </CardContent>
                    </Card>
                </Grid>
            </Grid>
        </Box>
    );
}
