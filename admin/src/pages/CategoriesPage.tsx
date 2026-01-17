import {
    Add as AddIcon,
    Delete as DeleteIcon,
    Edit as EditIcon,
    AutoAwesome as GenerateIcon,
} from '@mui/icons-material';
import {
    Alert,
    Box,
    Button,
    Card,
    Chip,
    CircularProgress,
    Dialog,
    DialogActions,
    DialogContent,
    DialogTitle,
    FormControl,
    FormControlLabel,
    IconButton,
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
import { useState } from 'react';
import { createCategory, deleteCategory, generateCategoryLabels, getCategories, updateCategory } from '../api';
import EmojiPicker from '../components/EmojiPicker';
import { AGE_GROUPS, LANGUAGES, LANGUAGE_NAMES, type AgeGroup, type Category, type CreateCategoryDto } from '../types';

const INITIAL_FORM: CreateCategoryDto = {
    emoji: '📝',
    age_group: 'adults',
    label: { en: '' },
    requires_consent: false,
    is_active: true,
    sort_order: 0,
};

export default function CategoriesPage() {
    const queryClient = useQueryClient();
    const [dialogOpen, setDialogOpen] = useState(false);
    const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
    const [selectedCategory, setSelectedCategory] = useState<Category | null>(null);
    const [form, setForm] = useState<CreateCategoryDto>(INITIAL_FORM);
    const [snackbar, setSnackbar] = useState<{ open: boolean; message: string; severity: 'success' | 'error' }>({
        open: false,
        message: '',
        severity: 'success',
    });

    const { data: categories, isLoading, error } = useQuery({
        queryKey: ['categories'],
        queryFn: () => getCategories(),
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

    const deleteMutation = useMutation({
        mutationFn: deleteCategory,
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['categories'] });
            setDeleteDialogOpen(false);
            setSnackbar({ open: true, message: 'Category deleted successfully', severity: 'success' });
        },
        onError: () => {
            setSnackbar({ open: true, message: 'Failed to delete category', severity: 'error' });
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
        setForm(INITIAL_FORM);
        setDialogOpen(true);
    };

    const handleEdit = (category: Category) => {
        setSelectedCategory(category);
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

    const handleDelete = (category: Category) => {
        setSelectedCategory(category);
        setDeleteDialogOpen(true);
    };

    const handleSubmit = () => {
        if (selectedCategory) {
            updateMutation.mutate({ id: selectedCategory.id, data: form });
        } else {
            createMutation.mutate(form);
        }
    };

    const handleConfirmDelete = () => {
        if (selectedCategory) {
            deleteMutation.mutate(selectedCategory.id);
        }
    };

    const updateLabel = (lang: string, value: string) => {
        setForm((prev) => ({
            ...prev,
            label: { ...prev.label, [lang]: value },
        }));
    };

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
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
                <Box>
                    <Typography variant="h4" fontWeight={700}>
                        Categories
                    </Typography>
                    <Typography color="text.secondary">Manage truth or dare categories</Typography>
                </Box>
                <Button variant="contained" startIcon={<AddIcon />} onClick={handleCreate}>
                    Add Category
                </Button>
            </Box>

            <Card>
                <TableContainer>
                    <Table>
                        <TableHead>
                            <TableRow>
                                <TableCell>Emoji</TableCell>
                                <TableCell>Label (EN)</TableCell>
                                <TableCell>Age Group</TableCell>
                                <TableCell>Consent</TableCell>
                                <TableCell>Status</TableCell>
                                <TableCell>Order</TableCell>
                                <TableCell align="right">Actions</TableCell>
                            </TableRow>
                        </TableHead>
                        <TableBody>
                            {categories?.map((category) => (
                                <TableRow key={category.id}>
                                    <TableCell>
                                        <Typography variant="h5">{category.emoji}</Typography>
                                    </TableCell>
                                    <TableCell>{category.label.en || '-'}</TableCell>
                                    <TableCell>
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
                                        />
                                    </TableCell>
                                    <TableCell>
                                        <Chip
                                            label={category.requires_consent ? 'Yes' : 'No'}
                                            size="small"
                                            variant="outlined"
                                        />
                                    </TableCell>
                                    <TableCell>
                                        <Chip
                                            label={category.is_active ? 'Active' : 'Inactive'}
                                            size="small"
                                            color={category.is_active ? 'success' : 'default'}
                                        />
                                    </TableCell>
                                    <TableCell>{category.sort_order}</TableCell>
                                    <TableCell align="right">
                                        <IconButton size="small" onClick={() => handleEdit(category)}>
                                            <EditIcon fontSize="small" />
                                        </IconButton>
                                        <IconButton size="small" color="error" onClick={() => handleDelete(category)}>
                                            <DeleteIcon fontSize="small" />
                                        </IconButton>
                                    </TableCell>
                                </TableRow>
                            ))}
                            {categories?.length === 0 && (
                                <TableRow>
                                    <TableCell colSpan={7} align="center">
                                        <Typography color="text.secondary" sx={{ py: 4 }}>
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
                <DialogTitle>{selectedCategory ? 'Edit Category' : 'Create Category'}</DialogTitle>
                <DialogContent>
                    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, mt: 1 }}>
                        <Box sx={{ display: 'flex', gap: 2, alignItems: 'center' }}>
                            <EmojiPicker
                                value={form.emoji}
                                onChange={(emoji) => setForm({ ...form, emoji })}
                            />
                            <FormControl size="small" sx={{ minWidth: 100 }}>
                                <InputLabel>Age Group</InputLabel>
                                <Select
                                    value={form.age_group}
                                    label="Age Group"
                                    onChange={(e) => setForm({ ...form, age_group: e.target.value as AgeGroup })}
                                >
                                    {AGE_GROUPS.map((group) => (
                                        <MenuItem key={group} value={group}>
                                            {group.charAt(0).toUpperCase() + group.slice(1)}
                                        </MenuItem>
                                    ))}
                                </Select>
                            </FormControl>
                            <TextField
                                label="Sort Order"
                                type="number"
                                size="small"
                                value={form.sort_order}
                                onChange={(e) => setForm({ ...form, sort_order: parseInt(e.target.value) || 0 })}
                                sx={{ width: 90 }}
                            />
                            <FormControlLabel
                                control={
                                    <Switch
                                        checked={form.requires_consent}
                                        onChange={(e) => setForm({ ...form, requires_consent: e.target.checked })}
                                        size="small"
                                    />
                                }
                                label="Consent"
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

                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mt: 1 }}>
                            <Typography variant="subtitle2">
                                Labels (multilingual)
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
                        <Box sx={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 2 }}>
                            {LANGUAGES.map((lang) => (
                                <TextField
                                    key={lang}
                                    label={`Label (${LANGUAGE_NAMES[lang]})`}
                                    value={form.label[lang] || ''}
                                    onChange={(e) => updateLabel(lang, e.target.value)}
                                    size="small"
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

            {/* Delete Confirmation Dialog */}
            <Dialog open={deleteDialogOpen} onClose={() => setDeleteDialogOpen(false)}>
                <DialogTitle>Delete Category</DialogTitle>
                <DialogContent>
                    <Typography>
                        Are you sure you want to delete "{selectedCategory?.label.en}"? This action cannot be undone.
                    </Typography>
                </DialogContent>
                <DialogActions>
                    <Button onClick={() => setDeleteDialogOpen(false)}>Cancel</Button>
                    <Button
                        variant="contained"
                        color="error"
                        onClick={handleConfirmDelete}
                        disabled={deleteMutation.isPending}
                    >
                        {deleteMutation.isPending ? <CircularProgress size={20} /> : 'Delete'}
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
