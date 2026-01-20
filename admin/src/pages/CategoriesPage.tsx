import {
    Add as AddIcon,
    DragIndicator as DragIcon,
    ExpandLess as ExpandLessIcon,
    FilterList as FilterIcon,
    AutoAwesome as GenerateIcon,
} from '@mui/icons-material';
import {
    Alert,
    Box,
    Button,
    Card,
    Chip,
    CircularProgress,
    Collapse,
    Dialog,
    DialogActions,
    DialogContent,
    DialogTitle,
    FormControl,
    FormControlLabel,
    InputLabel,
    MenuItem,
    Select,
    Snackbar,
    Switch,
    Table,
    TableBody,
    TableCell,
    TableContainer,
    TableHead,
    TableRow,
    TextField,
    Typography,
} from '@mui/material';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useCallback, useState } from 'react';
import { createCategory, generateCategoryLabels, getCategories, reorderCategories, updateCategory } from '../api';
import EmojiPicker from '../components/EmojiPicker';
import { AGE_GROUPS, LANGUAGES, LANGUAGE_NAMES, type AgeGroup, type Category, type CategoryFilter, type CreateCategoryDto } from '../types';

const INITIAL_FORM: CreateCategoryDto = {
    emoji: '📝',
    age_group: 'adults',
    label: { en: '' },
    requires_consent: false,
    is_active: true,
    sort_order: 0,
};

// Validation errors type
interface CategoryFormErrors {
    emoji?: string;
    age_group?: string;
    label_en?: string;
}

export default function CategoriesPage() {
    const queryClient = useQueryClient();
    const [dialogOpen, setDialogOpen] = useState(false);
    const [selectedCategory, setSelectedCategory] = useState<Category | null>(null);
    const [form, setForm] = useState<CreateCategoryDto>(INITIAL_FORM);
    const [formErrors, setFormErrors] = useState<CategoryFormErrors>({});
    const [snackbar, setSnackbar] = useState<{ open: boolean; message: string; severity: 'success' | 'error' }>({
        open: false,
        message: '',
        severity: 'success',
    });
    const [draggedIndex, setDraggedIndex] = useState<number | null>(null);
    const [dragOverIndex, setDragOverIndex] = useState<number | null>(null);
    const [filterOpen, setFilterOpen] = useState(false);

    // Filter state: 'all' | 'active' | 'inactive' - default to 'all'
    const [statusFilter, setStatusFilter] = useState<'all' | 'active' | 'inactive'>('all');

    // Validate category form
    const validateCategoryForm = (): boolean => {
        const errors: CategoryFormErrors = {};

        if (!form.emoji || form.emoji.trim() === '') {
            errors.emoji = 'Emoji is required';
        }
        if (!form.age_group) {
            errors.age_group = 'Age group is required';
        }
        if (!form.label.en || form.label.en.trim() === '') {
            errors.label_en = 'English label is required';
        }

        setFormErrors(errors);
        return Object.keys(errors).length === 0;
    };

    // Build filter based on status
    const filter: CategoryFilter | undefined = statusFilter === 'all'
        ? undefined  // Don't pass filter to get all categories
        : { active: statusFilter === 'active' };

    const { data: categories, isLoading, error } = useQuery({
        queryKey: ['categories', statusFilter],
        queryFn: () => filter ? getCategories(filter) : getCategories(),
    });

    const createMutation = useMutation({
        mutationFn: createCategory,
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['categories'] });
            setDialogOpen(false);
            setSnackbar({ open: true, message: 'Category created successfully', severity: 'success' });
        },
        onError: () => {
            setSnackbar({ open: true, message: 'Failed to create category', severity: 'error' });
        },
    });

    const updateMutation = useMutation({
        mutationFn: ({ id, data }: { id: string; data: Partial<CreateCategoryDto> }) => updateCategory(id, data),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['categories'] });
            setDialogOpen(false);
            setSnackbar({ open: true, message: 'Category updated successfully', severity: 'success' });
        },
        onError: () => {
            setSnackbar({ open: true, message: 'Failed to update category', severity: 'error' });
        },
    });

    const reorderMutation = useMutation({
        mutationFn: reorderCategories,
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['categories'] });
            setSnackbar({ open: true, message: 'Categories reordered', severity: 'success' });
        },
        onError: () => {
            setSnackbar({ open: true, message: 'Failed to reorder categories', severity: 'error' });
        },
    });

    const generateLabelsMutation = useMutation({
        mutationFn: (categoryName: string) => generateCategoryLabels(categoryName),
        onSuccess: (data) => {
            if (data.success && data.labels) {
                setForm((prev) => ({
                    ...prev,
                    label: { ...prev.label, ...data.labels },
                }));
                setSnackbar({ open: true, message: 'Labels generated successfully', severity: 'success' });
            }
        },
        onError: () => {
            setSnackbar({ open: true, message: 'Failed to generate labels', severity: 'error' });
        },
    });

    const handleCreate = () => {
        setSelectedCategory(null);
        setFormErrors({});
        // Set sort_order to be after the last category
        const maxOrder = categories?.reduce((max, cat) => Math.max(max, cat.sort_order), 0) || 0;
        setForm({ ...INITIAL_FORM, sort_order: maxOrder + 1 });
        setDialogOpen(true);
    };

    const handleEdit = (category: Category) => {
        setSelectedCategory(category);
        setFormErrors({});
        setForm({
            emoji: category.emoji,
            age_group: category.age_group,
            label: category.label,
            requires_consent: category.requires_consent,
            is_active: category.is_active,
            sort_order: category.sort_order,
        });
        setDialogOpen(true);
    };

    const handleSubmit = () => {
        if (!validateCategoryForm()) {
            return;
        }
        if (selectedCategory) {
            updateMutation.mutate({ id: selectedCategory.id, data: form });
        } else {
            createMutation.mutate(form);
        }
    };

    const updateLabel = (lang: string, value: string) => {
        setForm((prev) => ({
            ...prev,
            label: { ...prev.label, [lang]: value },
        }));
    };

    // Drag and drop handlers
    const handleDragStart = useCallback((e: React.DragEvent, index: number) => {
        setDraggedIndex(index);
        e.dataTransfer.effectAllowed = 'move';
        e.dataTransfer.setData('text/plain', index.toString());
    }, []);

    const handleDragOver = useCallback((e: React.DragEvent, index: number) => {
        e.preventDefault();
        e.dataTransfer.dropEffect = 'move';
        setDragOverIndex(index);
    }, []);

    const handleDrop = useCallback((e: React.DragEvent, dropIndex: number) => {
        e.preventDefault();
        setDragOverIndex(null);
        if (draggedIndex === null || draggedIndex === dropIndex || !categories) {
            setDraggedIndex(null);
            return;
        }

        const newCategories = [...categories];
        const [draggedItem] = newCategories.splice(draggedIndex, 1);
        newCategories.splice(dropIndex, 0, draggedItem);

        // Create reorder items with new sort orders
        const items = newCategories.map((cat, idx) => ({
            id: cat.id,
            sort_order: idx + 1,
        }));

        reorderMutation.mutate(items);
        setDraggedIndex(null);
    }, [draggedIndex, categories, reorderMutation]);

    const handleDragEnd = useCallback(() => {
        setDraggedIndex(null);
        setDragOverIndex(null);
    }, []);

    if (isLoading) {
        return (
            <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '50vh' }}>
                <CircularProgress />
            </Box>
        );
    }

    if (error) {
        return <Alert severity="error">Failed to load categories</Alert>;
    }

    return (
        <Box>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
                <Typography variant="h5" fontWeight={700}>
                    Categories {categories && <Chip label={categories.length} size="small" sx={{ ml: 1, height: 22 }} />}
                </Typography>
                <Box sx={{ display: 'flex', gap: 1 }}>
                    <Button
                        variant="outlined"
                        size="small"
                        startIcon={filterOpen ? <ExpandLessIcon /> : <FilterIcon />}
                        onClick={() => setFilterOpen(!filterOpen)}
                    >
                        Filters
                    </Button>
                    <Button variant="contained" size="small" startIcon={<AddIcon />} onClick={handleCreate}>
                        Add
                    </Button>
                </Box>
            </Box>

            {/* Filters */}
            <Collapse in={filterOpen}>
                <Card sx={{ mb: 2, p: 1.5 }}>
                    <Box sx={{ display: 'flex', gap: 1.5, flexWrap: 'wrap', alignItems: 'center' }}>
                        <FormControl size="small" sx={{ minWidth: 140 }}>
                            <InputLabel>Status</InputLabel>
                            <Select
                                value={statusFilter}
                                label="Status"
                                onChange={(e) => setStatusFilter(e.target.value as 'all' | 'active' | 'inactive')}
                            >
                                <MenuItem value="all">All</MenuItem>
                                <MenuItem value="active">Active</MenuItem>
                                <MenuItem value="inactive">Inactive</MenuItem>
                            </Select>
                        </FormControl>
                    </Box>
                </Card>
            </Collapse>

            <Card>
                <TableContainer>
                    <Table size="small">
                        <TableHead>
                            <TableRow>
                                <TableCell sx={{ py: 1, width: 40 }}></TableCell>
                                <TableCell sx={{ py: 1 }}>Emoji</TableCell>
                                <TableCell sx={{ py: 1 }}>Label</TableCell>
                                <TableCell sx={{ py: 1 }}>Age</TableCell>
                                <TableCell sx={{ py: 1 }}>Consent</TableCell>
                                <TableCell sx={{ py: 1 }}>Status</TableCell>
                            </TableRow>
                        </TableHead>
                        <TableBody>
                            {categories?.map((category, index) => (
                                <TableRow
                                    key={category.id}
                                    hover
                                    draggable
                                    onDragStart={(e) => handleDragStart(e, index)}
                                    onDragOver={(e) => handleDragOver(e, index)}
                                    onDragLeave={() => setDragOverIndex(null)}
                                    onDrop={(e) => handleDrop(e, index)}
                                    onDragEnd={handleDragEnd}
                                    sx={{
                                        cursor: 'grab',
                                        opacity: draggedIndex === index ? 0.5 : 1,
                                        '&:active': { cursor: 'grabbing' },
                                        ...(dragOverIndex === index && draggedIndex !== index && {
                                            borderTop: '2px solid',
                                            borderTopColor: 'primary.main',
                                            backgroundColor: 'action.hover',
                                        }),
                                    }}
                                >
                                    <TableCell sx={{ py: 0.5, width: 40 }}>
                                        <DragIcon sx={{ color: 'text.secondary', fontSize: 18, verticalAlign: 'middle' }} />
                                    </TableCell>
                                    <TableCell
                                        sx={{ py: 0.5, cursor: 'pointer' }}
                                        onClick={() => handleEdit(category)}
                                    >
                                        <Typography fontSize="1.2rem">{category.emoji}</Typography>
                                    </TableCell>
                                    <TableCell
                                        sx={{ py: 0.5, cursor: 'pointer' }}
                                        onClick={() => handleEdit(category)}
                                    >
                                        {category.label.en || '-'}
                                    </TableCell>
                                    <TableCell sx={{ py: 0.5 }}>
                                        <Chip
                                            label={category.age_group}
                                            size="small"
                                            color={
                                                category.age_group === 'kids'
                                                    ? 'success'
                                                    : category.age_group === 'teen'
                                                        ? 'warning'
                                                        : 'error'
                                            }
                                            sx={{ height: 20, fontSize: '0.7rem' }}
                                        />
                                    </TableCell>
                                    <TableCell sx={{ py: 0.5 }}>
                                        <Chip
                                            label={category.requires_consent ? 'Yes' : 'No'}
                                            size="small"
                                            variant="outlined"
                                            sx={{ height: 20, fontSize: '0.7rem' }}
                                        />
                                    </TableCell>
                                    <TableCell sx={{ py: 0.5 }}>
                                        <Chip
                                            label={category.is_active ? 'Active' : 'Inactive'}
                                            size="small"
                                            color={category.is_active ? 'success' : 'default'}
                                            sx={{ height: 20, fontSize: '0.7rem' }}
                                        />
                                    </TableCell>
                                </TableRow>
                            ))}
                            {categories?.length === 0 && (
                                <TableRow>
                                    <TableCell colSpan={6} align="center">
                                        <Typography color="text.secondary" sx={{ py: 2 }}>
                                            No categories found. Create your first category!
                                        </Typography>
                                    </TableCell>
                                </TableRow>
                            )}
                        </TableBody>
                    </Table>
                </TableContainer>
            </Card>

            {/* Create/Edit Dialog */}
            <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="md" fullWidth>
                <DialogTitle>
                    <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                        <Typography variant="h6" component="span">
                            {selectedCategory ? 'Edit Category' : 'Create Category'}
                        </Typography>
                        <Button
                            size="small"
                            variant="outlined"
                            startIcon={generateLabelsMutation.isPending ? <CircularProgress size={16} /> : <GenerateIcon />}
                            onClick={() => {
                                const englishLabel = form.label.en?.trim();
                                if (!englishLabel) {
                                    setSnackbar({ open: true, message: 'Please enter English label first', severity: 'error' });
                                    return;
                                }
                                generateLabelsMutation.mutate(englishLabel);
                            }}
                            disabled={generateLabelsMutation.isPending || !form.label.en?.trim()}
                            sx={{ textTransform: 'none' }}
                        >
                            Generate
                        </Button>
                    </Box>
                </DialogTitle>
                <DialogContent>
                    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, mt: 1 }}>
                        <Box sx={{ display: 'flex', gap: 2, alignItems: 'flex-start' }}>
                            <Box>
                                <EmojiPicker
                                    value={form.emoji}
                                    onChange={(emoji) => {
                                        setForm({ ...form, emoji });
                                        if (formErrors.emoji) setFormErrors({ ...formErrors, emoji: undefined });
                                    }}
                                />
                                {formErrors.emoji && (
                                    <Typography variant="caption" color="error" sx={{ display: 'block', mt: 0.5 }}>
                                        {formErrors.emoji}
                                    </Typography>
                                )}
                            </Box>
                            <FormControl size="small" sx={{ minWidth: 120 }} error={!!formErrors.age_group}>
                                <InputLabel>Age Group *</InputLabel>
                                <Select
                                    value={form.age_group}
                                    label="Age Group *"
                                    onChange={(e) => {
                                        setForm({ ...form, age_group: e.target.value as AgeGroup });
                                        if (formErrors.age_group) setFormErrors({ ...formErrors, age_group: undefined });
                                    }}
                                >
                                    {AGE_GROUPS.map((group) => (
                                        <MenuItem key={group} value={group}>
                                            {group.charAt(0).toUpperCase() + group.slice(1)}
                                        </MenuItem>
                                    ))}
                                </Select>
                                {formErrors.age_group && (
                                    <Typography variant="caption" color="error">{formErrors.age_group}</Typography>
                                )}
                            </FormControl>
                            <FormControlLabel
                                control={
                                    <Switch
                                        checked={form.requires_consent}
                                        onChange={(e) => setForm({ ...form, requires_consent: e.target.checked })}
                                        size="small"
                                    />
                                }
                                label="Consent Required"
                            />
                            <FormControlLabel
                                control={
                                    <Switch
                                        checked={form.is_active}
                                        onChange={(e) => setForm({ ...form, is_active: e.target.checked })}
                                        size="small"
                                    />
                                }
                                label="Active"
                            />
                        </Box>

                        <Typography variant="subtitle2" sx={{ mt: 1 }}>
                            Labels (multilingual)
                        </Typography>

                        <Box sx={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 2 }}>
                            {LANGUAGES.map((lang) => (
                                <TextField
                                    key={lang}
                                    label={`Label (${LANGUAGE_NAMES[lang]})${lang === 'en' ? ' *' : ''}`}
                                    value={form.label[lang] || ''}
                                    onChange={(e) => {
                                        updateLabel(lang, e.target.value);
                                        if (lang === 'en' && formErrors.label_en) {
                                            setFormErrors({ ...formErrors, label_en: undefined });
                                        }
                                    }}
                                    size="small"
                                    error={lang === 'en' && !!formErrors.label_en}
                                    helperText={lang === 'en' ? formErrors.label_en : undefined}
                                    required={lang === 'en'}
                                />
                            ))}
                        </Box>
                    </Box>
                </DialogContent>
                <DialogActions>
                    <Button onClick={() => setDialogOpen(false)}>Cancel</Button>
                    <Button
                        variant="contained"
                        onClick={handleSubmit}
                        disabled={createMutation.isPending || updateMutation.isPending}
                    >
                        {createMutation.isPending || updateMutation.isPending ? (
                            <CircularProgress size={20} />
                        ) : selectedCategory ? (
                            'Update'
                        ) : (
                            'Create'
                        )}
                    </Button>
                </DialogActions>
            </Dialog>

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
