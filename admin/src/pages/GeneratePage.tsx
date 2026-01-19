import { AutoAwesome as GenerateIcon } from '@mui/icons-material';
import {
    Alert,
    Box,
    Button,
    Card,
    CardContent,
    CircularProgress,
    FormControl,
    InputLabel,
    MenuItem,
    Select,
    Snackbar,
    TextField,
    Typography,
} from '@mui/material';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useState } from 'react';
import { generateTasks, getCategories } from '../api';
import {
    AGE_GROUPS,
    LANGUAGES,
    LANGUAGE_NAMES,
    type AgeGroup,
    type GenerateRequest,
    type Language,
} from '../types';

export default function GeneratePage() {
    const queryClient = useQueryClient();
    const [form, setForm] = useState<GenerateRequest>({
        age_group: null,
        category_id: null,
        language: null,
        count: 10,
    });
    const [snackbar, setSnackbar] = useState<{ open: boolean; message: string; severity: 'success' | 'error' }>({
        open: false,
        message: '',
        severity: 'success',
    });

    const { data: categories, isLoading: loadingCategories } = useQuery({
        queryKey: ['categories'],
        queryFn: () => getCategories(),
    });

    const generateMutation = useMutation({
        mutationFn: generateTasks,
        onSuccess: (data) => {
            queryClient.invalidateQueries({ queryKey: ['tasks'] });
            const msg = `Generated ${data.tasks_created} tasks (${data.total_truths_count} truths, ${data.total_dares_count} dares) across ${data.combinations_count} combination(s)`;
            setSnackbar({ open: true, message: msg, severity: 'success' });
        },
        onError: (error: Error) => {
            setSnackbar({ open: true, message: `Failed to generate tasks: ${error.message}`, severity: 'error' });
        },
    });

    const handleGenerate = () => {
        generateMutation.mutate(form);
    };

    // Filter categories based on selected age group
    const filteredCategories = categories?.filter((cat) => {
        if (!form.age_group) return true; // Show all if "All" selected
        if (form.age_group === 'kids') {
            return cat.age_group === 'kids';
        } else if (form.age_group === 'teen') {
            return cat.age_group === 'kids' || cat.age_group === 'teen';
        }
        return true; // adults can see all
    });

    if (loadingCategories) {
        return (
            <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '50vh' }}>
                <CircularProgress />
            </Box>
        );
    }

    return (
        <Box>
            <Typography variant="h5" fontWeight={700} sx={{ mb: 2 }}>
                Generate Tasks
            </Typography>

            <Card sx={{ maxWidth: 500 }}>
                <CardContent sx={{ py: 2, '&:last-child': { pb: 2 } }}>
                    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                        <Box sx={{ display: 'flex', gap: 2 }}>
                            <FormControl size="small" sx={{ flex: 1 }}>
                                <InputLabel shrink>Age Group</InputLabel>
                                <Select
                                    value={form.age_group ?? ''}
                                    label="Age Group"
                                    displayEmpty
                                    notched
                                    renderValue={(selected) => selected ? (selected as string).charAt(0).toUpperCase() + (selected as string).slice(1) : 'All'}
                                    onChange={(e) => {
                                        const rawValue = e.target.value as string;
                                        const value = rawValue === '' ? null : rawValue as AgeGroup;
                                        setForm({ ...form, age_group: value, category_id: null });
                                    }}
                                >
                                    <MenuItem value="">
                                        <em>All</em>
                                    </MenuItem>
                                    {AGE_GROUPS.map((group) => (
                                        <MenuItem key={group} value={group}>
                                            {group.charAt(0).toUpperCase() + group.slice(1)}
                                        </MenuItem>
                                    ))}
                                </Select>
                            </FormControl>

                            <FormControl size="small" sx={{ flex: 1 }}>
                                <InputLabel shrink>Language</InputLabel>
                                <Select
                                    value={form.language ?? ''}
                                    label="Language"
                                    displayEmpty
                                    notched
                                    renderValue={(selected) => selected ? LANGUAGE_NAMES[selected as Language] : 'All'}
                                    onChange={(e) => {
                                        const rawValue = e.target.value as string;
                                        const value = rawValue === '' ? null : rawValue as Language;
                                        setForm({ ...form, language: value });
                                    }}
                                >
                                    <MenuItem value="">
                                        <em>All</em>
                                    </MenuItem>
                                    {LANGUAGES.map((lang) => (
                                        <MenuItem key={lang} value={lang}>
                                            {LANGUAGE_NAMES[lang]}
                                        </MenuItem>
                                    ))}
                                </Select>
                            </FormControl>
                        </Box>

                        <FormControl size="small" fullWidth>
                            <InputLabel shrink>Category</InputLabel>
                            <Select
                                value={form.category_id ?? ''}
                                label="Category"
                                displayEmpty
                                notched
                                renderValue={(selected) => {
                                    if (!selected) return 'All Categories';
                                    const cat = filteredCategories?.find(c => c.id === selected);
                                    return cat ? `${cat.emoji} ${cat.label.en}` : 'All Categories';
                                }}
                                onChange={(e) => {
                                    const value = e.target.value === '' ? null : e.target.value;
                                    setForm({ ...form, category_id: value });
                                }}
                            >
                                <MenuItem value="">
                                    <em>All Categories</em>
                                </MenuItem>
                                {filteredCategories?.map((cat) => (
                                    <MenuItem key={cat.id} value={cat.id}>
                                        {cat.emoji} {cat.label.en} {cat.requires_consent && '🔞'}
                                    </MenuItem>
                                ))}
                            </Select>
                        </FormControl>

                        <Box sx={{ display: 'flex', gap: 2, alignItems: 'center' }}>
                            <TextField
                                size="small"
                                label="Count (per combination)"
                                type="number"
                                value={form.count}
                                onChange={(e) => setForm({ ...form, count: Math.min(50, Math.max(1, parseInt(e.target.value) || 1)) })}
                                inputProps={{ min: 1, max: 50 }}
                                sx={{ width: 180 }}
                            />
                            <Typography variant="caption" color="text.secondary">
                                {!form.category_id && !form.age_group && !form.language
                                    ? 'Will generate for all combinations'
                                    : `${form.count} truths + ${form.count} dares per combination`}
                            </Typography>
                        </Box>

                        <Button
                            variant="contained"
                            startIcon={generateMutation.isPending ? <CircularProgress size={16} color="inherit" /> : <GenerateIcon />}
                            onClick={handleGenerate}
                            disabled={generateMutation.isPending}
                        >
                            {generateMutation.isPending ? 'Generating...' : 'Generate'}
                        </Button>
                    </Box>
                </CardContent>
            </Card>

            <Snackbar
                open={snackbar.open}
                autoHideDuration={6000}
                onClose={() => setSnackbar({ ...snackbar, open: false })}
            >
                <Alert severity={snackbar.severity} onClose={() => setSnackbar({ ...snackbar, open: false })}>
                    {snackbar.message}
                </Alert>
            </Snackbar>
        </Box>
    );
}
