import {
    Add as AddIcon,
    Delete as DeleteIcon,
    ExpandLess as ExpandLessIcon,
    FilterList as FilterIcon
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
    IconButton,
    InputLabel,
    MenuItem,
    Select,
    Snackbar,
    Table,
    TableBody,
    TableCell,
    TableContainer,
    TableHead,
    TablePagination,
    TableRow,
    TextField,
    Typography,
} from '@mui/material';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useEffect, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { createTask, deleteTask, getCategories, getTasks, updateTask } from '../api';
import {
    LANGUAGES,
    LANGUAGE_NAMES,
    TASK_TYPES,
    type CreateTaskDto,
    type Language,
    type Task,
    type TaskFilter,
    type TaskType
} from '../types';

const INITIAL_FORM: CreateTaskDto = {
    category_id: '',
    type: 'truth',
    text: '',
    language: 'en',
};

// Validation errors type
interface TaskFormErrors {
    category_id?: string;
    type?: string;
    text?: string;
    language?: string;
}

// Parse initial filters from URL search params
const getInitialFilters = (searchParams: URLSearchParams): TaskFilter => {
    const filters: TaskFilter = {};
    const type = searchParams.get('type');
    const language = searchParams.get('language');
    const category = searchParams.get('category');

    if (type && TASK_TYPES.includes(type as TaskType)) {
        filters.types = [type as TaskType];
    }
    if (language && LANGUAGES.includes(language as Language)) {
        filters.language = language as Language;
    }
    if (category) {
        filters.category_ids = [category];
    }
    return filters;
};

export default function TasksPage() {
    const queryClient = useQueryClient();
    const [searchParams, setSearchParams] = useSearchParams();
    const [dialogOpen, setDialogOpen] = useState(false);
    const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
    const [filterOpen, setFilterOpen] = useState(() => {
        // Auto-open filters if URL has filter params
        return searchParams.has('type') || searchParams.has('language') || searchParams.has('category');
    });
    const [selectedTask, setSelectedTask] = useState<Task | null>(null);
    const [form, setForm] = useState<CreateTaskDto>(INITIAL_FORM);
    const [formErrors, setFormErrors] = useState<TaskFormErrors>({});
    const [page, setPage] = useState(0);
    const [rowsPerPage, setRowsPerPage] = useState(20);
    const [filters, setFilters] = useState<TaskFilter>(() => getInitialFilters(searchParams));
    const [snackbar, setSnackbar] = useState<{ open: boolean; message: string; severity: 'success' | 'error' }>({
        open: false,
        message: '',
        severity: 'success',
    });

    // Sync filters to URL
    useEffect(() => {
        const params = new URLSearchParams();
        if (filters.types?.length === 1) {
            params.set('type', filters.types[0]);
        }
        if (filters.language) {
            params.set('language', filters.language);
        }
        if (filters.category_ids?.length === 1) {
            params.set('category', filters.category_ids[0]);
        }
        setSearchParams(params, { replace: true });
    }, [filters, setSearchParams]);

    const { data: categories } = useQuery({
        queryKey: ['categories'],
        queryFn: () => getCategories(),
    });

    const { data: tasksData, isLoading, error } = useQuery({
        queryKey: ['tasks', page, rowsPerPage, filters],
        queryFn: () =>
            getTasks({
                ...filters,
                page: page + 1,
                page_size: rowsPerPage,
            }),
    });

    const createMutation = useMutation({
        mutationFn: createTask,
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['tasks'] });
            setDialogOpen(false);
            setSnackbar({ open: true, message: 'Task created successfully', severity: 'success' });
        },
        onError: () => {
            setSnackbar({ open: true, message: 'Failed to create task', severity: 'error' });
        },
    });

    const updateMutation = useMutation({
        mutationFn: ({ id, data }: { id: string; data: Partial<CreateTaskDto> }) => updateTask(id, data),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['tasks'] });
            setDialogOpen(false);
            setSnackbar({ open: true, message: 'Task updated successfully', severity: 'success' });
        },
        onError: () => {
            setSnackbar({ open: true, message: 'Failed to update task', severity: 'error' });
        },
    });

    const deleteMutation = useMutation({
        mutationFn: deleteTask,
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['tasks'] });
            setDeleteDialogOpen(false);
            setSnackbar({ open: true, message: 'Task deleted successfully', severity: 'success' });
        },
        onError: () => {
            setSnackbar({ open: true, message: 'Failed to delete task', severity: 'error' });
        },
    });

    // Validate task form
    const validateTaskForm = (): boolean => {
        const errors: TaskFormErrors = {};

        if (!form.category_id) {
            errors.category_id = 'Category is required';
        }
        if (!form.type) {
            errors.type = 'Type is required';
        }
        if (!form.text || form.text.trim() === '') {
            errors.text = 'Task text is required';
        }
        if (!form.language) {
            errors.language = 'Language is required';
        }

        setFormErrors(errors);
        return Object.keys(errors).length === 0;
    };

    const handleCreate = () => {
        setSelectedTask(null);
        setForm(INITIAL_FORM);
        setFormErrors({});
        setDialogOpen(true);
    };

    const handleEdit = (task: Task) => {
        setSelectedTask(task);
        setFormErrors({});
        setForm({
            category_id: task.category_id,
            type: task.type,
            text: task.text,
            language: task.language,
        });
        setDialogOpen(true);
    };

    const handleDelete = (task: Task) => {
        setSelectedTask(task);
        setDeleteDialogOpen(true);
    };

    const handleSubmit = () => {
        if (!validateTaskForm()) {
            return;
        }
        if (selectedTask) {
            updateMutation.mutate({ id: selectedTask.id, data: form });
        } else {
            createMutation.mutate(form);
        }
    };

    const handleConfirmDelete = () => {
        if (selectedTask) {
            deleteMutation.mutate(selectedTask.id);
        }
    };

    const getCategoryName = (categoryId: string): string => {
        const category = categories?.find((c) => c.id === categoryId);
        return category?.label.en || categoryId;
    };

    if (isLoading && !tasksData) {
        return (
            <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '50vh' }}>
                <CircularProgress />
            </Box>
        );
    }

    if (error) {
        return <Alert severity="error">Failed to load tasks</Alert>;
    }

    return (
        <Box>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
                <Typography variant="h5" fontWeight={700}>
                    Tasks
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
                            <InputLabel>Category</InputLabel>
                            <Select
                                multiple
                                value={filters.category_ids || []}
                                label="Category"
                                onChange={(e) =>
                                    setFilters({ ...filters, category_ids: e.target.value as string[] })
                                }
                            >
                                {categories?.map((cat) => (
                                    <MenuItem key={cat.id} value={cat.id}>
                                        {cat.emoji} {cat.label.en}
                                    </MenuItem>
                                ))}
                            </Select>
                        </FormControl>

                        <FormControl size="small" sx={{ minWidth: 100 }}>
                            <InputLabel>Type</InputLabel>
                            <Select
                                multiple
                                value={filters.types || []}
                                label="Type"
                                onChange={(e) => setFilters({ ...filters, types: e.target.value as TaskType[] })}
                            >
                                {TASK_TYPES.map((type) => (
                                    <MenuItem key={type} value={type}>
                                        {type.charAt(0).toUpperCase() + type.slice(1)}
                                    </MenuItem>
                                ))}
                            </Select>
                        </FormControl>

                        <FormControl size="small" sx={{ minWidth: 120 }}>
                            <InputLabel>Language</InputLabel>
                            <Select
                                multiple
                                value={filters.languages || []}
                                label="Language"
                                onChange={(e) =>
                                    setFilters({ ...filters, languages: e.target.value as Language[] })
                                }
                            >
                                {LANGUAGES.map((lang) => (
                                    <MenuItem key={lang} value={lang}>
                                        {LANGUAGE_NAMES[lang]}
                                    </MenuItem>
                                ))}
                            </Select>
                        </FormControl>

                        <Button
                            variant="text"
                            size="small"
                            onClick={() => {
                                setFilters({});
                                setPage(0);
                            }}
                        >
                            Clear
                        </Button>
                    </Box>
                </Card>
            </Collapse>

            <Card>
                <TableContainer>
                    <Table size="small">
                        <TableHead>
                            <TableRow>
                                <TableCell sx={{ py: 1 }}>Type</TableCell>
                                <TableCell sx={{ py: 1 }}>Text</TableCell>
                                <TableCell sx={{ py: 1 }}>Category</TableCell>
                                <TableCell sx={{ py: 1 }}>Lang</TableCell>
                                <TableCell sx={{ py: 1, width: 40 }}></TableCell>
                            </TableRow>
                        </TableHead>
                        <TableBody>
                            {tasksData?.data?.map((task) => (
                                <TableRow
                                    key={task.id}
                                    hover
                                    onClick={() => handleEdit(task)}
                                    sx={{ cursor: 'pointer' }}
                                >
                                    <TableCell sx={{ py: 0.5 }}>
                                        <Chip
                                            label={task.type}
                                            size="small"
                                            color={task.type === 'truth' ? 'primary' : 'secondary'}
                                            sx={{ height: 20, fontSize: '0.7rem' }}
                                        />
                                    </TableCell>
                                    <TableCell sx={{ py: 0.5, maxWidth: 400, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                                        {task.text || '-'}
                                    </TableCell>
                                    <TableCell sx={{ py: 0.5 }}>{getCategoryName(task.category_id)}</TableCell>
                                    <TableCell sx={{ py: 0.5 }}>
                                        <Chip
                                            label={task.language.toUpperCase()}
                                            size="small"
                                            variant="outlined"
                                            sx={{ height: 20, fontSize: '0.7rem' }}
                                        />
                                    </TableCell>
                                    <TableCell sx={{ py: 0.5 }} onClick={(e) => e.stopPropagation()}>
                                        <IconButton size="small" color="error" onClick={() => handleDelete(task)}>
                                            <DeleteIcon fontSize="small" />
                                        </IconButton>
                                    </TableCell>
                                </TableRow>
                            ))}
                            {(!tasksData?.data || tasksData.data.length === 0) && (
                                <TableRow>
                                    <TableCell colSpan={5} align="center">
                                        <Typography color="text.secondary" sx={{ py: 2 }}>
                                            No tasks found. Create your first task!
                                        </Typography>
                                    </TableCell>
                                </TableRow>
                            )}
                        </TableBody>
                    </Table>
                </TableContainer>
                <TablePagination
                    component="div"
                    count={tasksData?.total || 0}
                    page={page}
                    onPageChange={(_, newPage) => setPage(newPage)}
                    rowsPerPage={rowsPerPage}
                    onRowsPerPageChange={(e) => {
                        setRowsPerPage(parseInt(e.target.value, 10));
                        setPage(0);
                    }}
                    rowsPerPageOptions={[10, 20, 50, 100]}
                />
            </Card>

            {/* Create/Edit Dialog */}
            <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="sm" fullWidth>
                <DialogTitle>{selectedTask ? 'Edit Task' : 'Create Task'}</DialogTitle>
                <DialogContent>
                    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, mt: 1 }}>
                        <Box sx={{ display: 'flex', gap: 2 }}>
                            <FormControl sx={{ flex: 1 }} error={!!formErrors.category_id}>
                                <InputLabel>Category *</InputLabel>
                                <Select
                                    value={form.category_id}
                                    label="Category *"
                                    onChange={(e) => {
                                        setForm({ ...form, category_id: e.target.value });
                                        if (formErrors.category_id) setFormErrors({ ...formErrors, category_id: undefined });
                                    }}
                                >
                                    {categories?.map((cat) => (
                                        <MenuItem key={cat.id} value={cat.id}>
                                            {cat.emoji} {cat.label.en}
                                        </MenuItem>
                                    ))}
                                </Select>
                                {formErrors.category_id && (
                                    <Typography variant="caption" color="error">{formErrors.category_id}</Typography>
                                )}
                            </FormControl>
                            <FormControl sx={{ minWidth: 120 }} error={!!formErrors.type}>
                                <InputLabel>Type *</InputLabel>
                                <Select
                                    value={form.type}
                                    label="Type *"
                                    onChange={(e) => {
                                        setForm({ ...form, type: e.target.value as TaskType });
                                        if (formErrors.type) setFormErrors({ ...formErrors, type: undefined });
                                    }}
                                >
                                    {TASK_TYPES.map((type) => (
                                        <MenuItem key={type} value={type}>
                                            {type.charAt(0).toUpperCase() + type.slice(1)}
                                        </MenuItem>
                                    ))}
                                </Select>
                                {formErrors.type && (
                                    <Typography variant="caption" color="error">{formErrors.type}</Typography>
                                )}
                            </FormControl>
                        </Box>

                        <FormControl fullWidth error={!!formErrors.language}>
                            <InputLabel>Language *</InputLabel>
                            <Select
                                value={form.language}
                                label="Language *"
                                onChange={(e) => {
                                    setForm({ ...form, language: e.target.value as Language });
                                    if (formErrors.language) setFormErrors({ ...formErrors, language: undefined });
                                }}
                            >
                                {LANGUAGES.map((lang) => (
                                    <MenuItem key={lang} value={lang}>
                                        {LANGUAGE_NAMES[lang]}
                                    </MenuItem>
                                ))}
                            </Select>
                            {formErrors.language && (
                                <Typography variant="caption" color="error">{formErrors.language}</Typography>
                            )}
                        </FormControl>

                        <TextField
                            label="Task Text *"
                            value={form.text}
                            onChange={(e) => {
                                setForm({ ...form, text: e.target.value });
                                if (formErrors.text) setFormErrors({ ...formErrors, text: undefined });
                            }}
                            multiline
                            rows={3}
                            error={!!formErrors.text}
                            helperText={formErrors.text}
                            required
                            fullWidth
                            placeholder="Enter the task text..."
                        />
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
                        ) : selectedTask ? (
                            'Update'
                        ) : (
                            'Create'
                        )}
                    </Button>
                </DialogActions>
            </Dialog>

            {/* Delete Confirmation Dialog */}
            <Dialog open={deleteDialogOpen} onClose={() => setDeleteDialogOpen(false)}>
                <DialogTitle>Delete Task</DialogTitle>
                <DialogContent>
                    <Typography>
                        Are you sure you want to delete this task? This action cannot be undone.
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
