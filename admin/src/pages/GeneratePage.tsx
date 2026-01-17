import { AutoAwesome as GenerateIcon } from '@mui/icons-material';
import {
    Alert,
    Box,
    Button,
    Card,
    CardContent,
    CircularProgress,
    FormControl,
    FormControlLabel,
    InputLabel,
    MenuItem,
    Select,
    Snackbar,
    Switch,
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
        age_group: 'adults',
        category_id: '',
        category_name: '',
        language: 'en',
        count: 5,
        explicit_mode: false,
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
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['tasks'] });
            setSnackbar({ open: true, message: 'Tasks generated successfully!', severity: 'success' });
        },
        onError: (error: Error) => {
            setSnackbar({ open: true, message: `Failed to generate tasks: ${error.message}`, severity: 'error' });
        },
    });

    const handleGenerate = () => {
        if (!form.category_id) {
            setSnackbar({ open: true, message: 'Please select a category', severity: 'error' });
            return;
        }
        generateMutation.mutate(form);
    };

    const filteredCategories = categories?.filter((cat) => {
        // Filter categories based on age group compatibility
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
            <Box sx={{ mb: 3 }}>
                <Typography variant="h4" fontWeight={700}>
                    Generate Tasks
                </Typography>
                <Typography color="text.secondary">
                    Use AI to generate truth or dare tasks automatically
                </Typography>
            </Box>

            <Card sx={{ maxWidth: 600 }}>
                <CardContent>
                    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
                        <FormControl fullWidth>
                            <InputLabel>Age Group</InputLabel>
                            <Select
                                value={form.age_group}
                                label="Age Group"
                                onChange={(e) => {
                                    setForm({ ...form, age_group: e.target.value as AgeGroup, category_id: '', category_name: '' });
                                }}
                            >
                                {AGE_GROUPS.map((group) => (
                                    <MenuItem key={group} value={group}>
                                        {group.charAt(0).toUpperCase() + group.slice(1)}
                                        {group === 'kids' && ' (0-12)'}
                                        {group === 'teen' && ' (13-17)'}
                                        {group === 'adults' && ' (18+)'}
                                    </MenuItem>
                                ))}
                            </Select>
                        </FormControl>

                        <FormControl fullWidth>
                            <InputLabel>Category</InputLabel>
                            <Select
                                value={form.category_id}
                                label="Category"
                                onChange={(e) => {
                                    const selectedCategory = filteredCategories?.find(cat => cat.id === e.target.value);
                                    setForm({
                                        ...form,
                                        category_id: e.target.value,
                                        category_name: selectedCategory?.label.en ?? '',
                                        // Auto-set explicit_mode based on category's requires_consent
                                        explicit_mode: selectedCategory?.requires_consent ?? false
                                    });
                                }}
                            >
                                {filteredCategories?.map((cat) => (
                                    <MenuItem key={cat.id} value={cat.id}>
                                        {cat.emoji} {cat.label.en} {cat.requires_consent && '🔞'}
                                    </MenuItem>
                                ))}
                            </Select>
                        </FormControl>

                        <FormControl fullWidth>
                            <InputLabel>Language</InputLabel>
                            <Select
                                value={form.language}
                                label="Language"
                                onChange={(e) => setForm({ ...form, language: e.target.value as Language })}
                            >
                                {LANGUAGES.map((lang) => (
                                    <MenuItem key={lang} value={lang}>
                                        {LANGUAGE_NAMES[lang]}
                                    </MenuItem>
                                ))}
                            </Select>
                        </FormControl>

                        <TextField
                            fullWidth
                            label="Number of Tasks"
                            type="number"
                            value={form.count}
                            onChange={(e) => setForm({ ...form, count: Math.min(50, Math.max(1, parseInt(e.target.value) || 1)) })}
                            inputProps={{ min: 1, max: 50 }}
                            helperText="Generate 1-50 tasks at a time"
                        />

                        {form.age_group === 'adults' && (
                            <FormControlLabel
                                control={
                                    <Switch
                                        checked={form.explicit_mode}
                                        onChange={(e) => setForm({ ...form, explicit_mode: e.target.checked })}
                                    />
                                }
                                label={
                                    <Box>
                                        <Typography>Explicit Mode</Typography>
                                        <Typography variant="caption" color="text.secondary">
                                            Generate adult-only content (requires consent category)
                                        </Typography>
                                    </Box>
                                }
                            />
                        )}

                        <Alert severity="info">
                            The AI will generate a mix of truths and dares based on the selected filters.
                            Generated tasks will be saved as active and can be edited later.
                        </Alert>

                        <Button
                            variant="contained"
                            size="large"
                            startIcon={generateMutation.isPending ? <CircularProgress size={20} color="inherit" /> : <GenerateIcon />}
                            onClick={handleGenerate}
                            disabled={generateMutation.isPending || !form.category_id}
                            sx={{ py: 1.5 }}
                        >
                            {generateMutation.isPending ? 'Generating...' : 'Generate Tasks'}
                        </Button>
                    </Box>
                </CardContent>
            </Card>

            <Snackbar
                open={snackbar.open}
                autoHideDuration={4000}
                onClose={() => setSnackbar({ ...snackbar, open: false })}
            >
                <Alert severity={snackbar.severity} onClose={() => setSnackbar({ ...snackbar, open: false })}>
                    {snackbar.message}
                </Alert>
            </Snackbar>
        </Box>
    );
}
