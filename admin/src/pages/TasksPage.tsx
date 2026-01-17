import {
    Add as AddIcon,
    Delete as DeleteIcon,
    Edit as EditIcon,
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
    TablePagination,
    TableRow,
    TextField,
    Typography,
} from '@mui/material';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useState } from 'react';
import { createTask, deleteTask, getCategories, getTasks, updateTask } from '../api';
import {
    AGE_GROUPS,
    LANGUAGES,
    LANGUAGE_NAMES,
    TASK_TYPES,
    type AgeGroup,
    type CreateTaskDto,
    type Task,
    type TaskFilter,
    type TaskType
} from '../types';

const INITIAL_FORM: CreateTaskDto = {
    category_id: '',
    type: 'truth',
    text: { en: '' },
    hint: {},
    min_age: 0,
    requires_consent: false,
};

export default function TasksPage() {
    const queryClient = useQueryClient();
    const [dialogOpen, setDialogOpen] = useState(false);
    const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
    const [filterOpen, setFilterOpen] = useState(false);
    const [selectedTask, setSelectedTask] = useState<Task | null>(null);
    const [form, setForm] = useState<CreateTaskDto>(INITIAL_FORM);
    const [page, setPage] = useState(0);
    const [rowsPerPage, setRowsPerPage] = useState(20);
    const [filters, setFilters] = useState<TaskFilter>({});
    const [snackbar, setSnackbar] = useState<{ open: boolean; message: string; severity: 'success' | 'error' }>({
        open: false,
        message: '',
        severity: 'success',
    });

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

    const handleCreate = () => {
        setSelectedTask(null);
        setForm(INITIAL_FORM);
        setDialogOpen(true);
    };

    const handleEdit = (task: Task) => {
        setSelectedTask(task);
        setForm({
            category_id: task.category_id,
            type: task.type,
            text: task.text,
            hint: task.hint || {},
            min_age: getMinAgeForGroup(task.age_group),
            requires_consent: task.requires_consent,
        });
        setDialogOpen(true);
    };

    const handleDelete = (task: Task) => {
        setSelectedTask(task);
        setDeleteDialogOpen(true);
    };

    const handleSubmit = () => {
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

    const updateText = (lang: string, value: string) => {
        setForm((prev) => ({
            ...prev,
            text: { ...prev.text, [lang]: value },
        }));
    };

    const updateHint = (lang: string, value: string) => {
        setForm((prev) => ({
            ...prev,
            hint: { ...(prev.hint || {}), [lang]: value },
        }));
    };

    const getMinAgeForGroup = (group: AgeGroup): number => {
        switch (group) {
            case 'kids':
                return 0;
            case 'teen':
                return 13;
            case 'adults':
                return 18;
            default:
                return 0;
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
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
                <Box>
                    <Typography variant="h4" fontWeight={700}>
                        Tasks
                    </Typography>
                    <Typography color="text.secondary">Manage truth and dare tasks</Typography>
                </Box>
                <Box sx={{ display: 'flex', gap: 1 }}>
                    <Button
                        variant="outlined"
                        startIcon={filterOpen ? <ExpandLessIcon /> : <FilterIcon />}
                        onClick={() => setFilterOpen(!filterOpen)}
                    >
                        Filters
                    </Button>
                    <Button variant="contained" startIcon={<AddIcon />} onClick={handleCreate}>
                        Add Task
                    </Button>
                </Box>
            </Box>

            {/* Filters */}
            <Collapse in={filterOpen}>
                <Card sx={{ mb: 3, p: 2 }}>
                    <Box sx={{ display: 'flex', gap: 2, flexWrap: 'wrap' }}>
                        <FormControl size="small" sx={{ minWidth: 150 }}>
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

                        <FormControl size="small" sx={{ minWidth: 120 }}>
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
                            <InputLabel>Age Group</InputLabel>
                            <Select
                                multiple
                                value={filters.age_groups || []}
                                label="Age Group"
                                onChange={(e) =>
                                    setFilters({ ...filters, age_groups: e.target.value as AgeGroup[] })
                                }
                            >
                                {AGE_GROUPS.map((group) => (
                                    <MenuItem key={group} value={group}>
                                        {group.charAt(0).toUpperCase() + group.slice(1)}
                                    </MenuItem>
                                ))}
                            </Select>
                        </FormControl>

                        <FormControl size="small" sx={{ minWidth: 120 }}>
                            <InputLabel>Status</InputLabel>
                            <Select
                                value={filters.active === undefined ? '' : String(filters.active)}
                                label="Status"
                                onChange={(e) =>
                                    setFilters({
                                        ...filters,
                                        active: e.target.value === '' ? undefined : e.target.value === 'true',
                                    })
                                }
                            >
                                <MenuItem value="">All</MenuItem>
                                <MenuItem value="true">Active</MenuItem>
                                <MenuItem value="false">Inactive</MenuItem>
                            </Select>
                        </FormControl>

                        <Button
                            variant="text"
                            onClick={() => {
                                setFilters({});
                                setPage(0);
                            }}
                        >
                            Clear Filters
                        </Button>
                    </Box>
                </Card>
            </Collapse>

            <Card>
                <TableContainer>
                    <Table>
                        <TableHead>
                            <TableRow>
                                <TableCell>Type</TableCell>
                                <TableCell>Text (EN)</TableCell>
                                <TableCell>Category</TableCell>
                                <TableCell>Age Group</TableCell>
                                <TableCell>Status</TableCell>
                                <TableCell align="right">Actions</TableCell>
                            </TableRow>
                        </TableHead>
                        <TableBody>
                            {tasksData?.data?.map((task) => (
                                <TableRow key={task.id}>
                                    <TableCell>
                                        <Chip
                                            label={task.type}
                                            size="small"
                                            color={task.type === 'truth' ? 'primary' : 'secondary'}
                                        />
                                    </TableCell>
                                    <TableCell sx={{ maxWidth: 300, overflow: 'hidden', textOverflow: 'ellipsis' }}>
                                        {task.text.en || '-'}
                                    </TableCell>
                                    <TableCell>{getCategoryName(task.category_id)}</TableCell>
                                    <TableCell>
                                        <Chip
                                            label={task.age_group}
                                            size="small"
                                            color={
                                                task.age_group === 'kids'
                                                    ? 'success'
                                                    : task.age_group === 'teen'
                                                        ? 'warning'
                                                        : 'error'
                                            }
                                        />
                                    </TableCell>
                                    <TableCell>
                                        <Chip
                                            label={task.is_active ? 'Active' : 'Inactive'}
                                            size="small"
                                            color={task.is_active ? 'success' : 'default'}
                                        />
                                    </TableCell>
                                    <TableCell align="right">
                                        <IconButton size="small" onClick={() => handleEdit(task)}>
                                            <EditIcon fontSize="small" />
                                        </IconButton>
                                        <IconButton size="small" color="error" onClick={() => handleDelete(task)}>
                                            <DeleteIcon fontSize="small" />
                                        </IconButton>
                                    </TableCell>
                                </TableRow>
                            ))}
                            {(!tasksData?.data || tasksData.data.length === 0) && (
                                <TableRow>
                                    <TableCell colSpan={7} align="center">
                                        <Typography color="text.secondary" sx={{ py: 4 }}>
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
            <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="md" fullWidth>
                <DialogTitle>{selectedTask ? 'Edit Task' : 'Create Task'}</DialogTitle>
                <DialogContent>
                    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, mt: 1 }}>
                        <Box sx={{ display: 'flex', gap: 2 }}>
                            <FormControl sx={{ flex: 1 }}>
                                <InputLabel>Category</InputLabel>
                                <Select
                                    value={form.category_id}
                                    label="Category"
                                    onChange={(e) => setForm({ ...form, category_id: e.target.value })}
                                >
                                    {categories?.map((cat) => (
                                        <MenuItem key={cat.id} value={cat.id}>
                                            {cat.emoji} {cat.label.en}
                                        </MenuItem>
                                    ))}
                                </Select>
                            </FormControl>
                            <FormControl sx={{ minWidth: 120 }}>
                                <InputLabel>Type</InputLabel>
                                <Select
                                    value={form.type}
                                    label="Type"
                                    onChange={(e) => setForm({ ...form, type: e.target.value as TaskType })}
                                >
                                    {TASK_TYPES.map((type) => (
                                        <MenuItem key={type} value={type}>
                                            {type.charAt(0).toUpperCase() + type.slice(1)}
                                        </MenuItem>
                                    ))}
                                </Select>
                            </FormControl>
                        </Box>

                        <TextField
                            label="Min Age"
                            type="number"
                            value={form.min_age}
                            onChange={(e) => setForm({ ...form, min_age: parseInt(e.target.value) || 0 })}
                            sx={{ width: 120 }}
                        />

                        <Typography variant="subtitle2" sx={{ mt: 1 }}>
                            Task Text (multilingual)
                        </Typography>
                        <Box sx={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 2 }}>
                            {LANGUAGES.map((lang) => (
                                <TextField
                                    key={lang}
                                    label={`Text (${LANGUAGE_NAMES[lang]})`}
                                    value={form.text[lang] || ''}
                                    onChange={(e) => updateText(lang, e.target.value)}
                                    size="small"
                                    multiline
                                    rows={2}
                                />
                            ))}
                        </Box>

                        <Typography variant="subtitle2" sx={{ mt: 1 }}>
                            Hint (optional, multilingual)
                        </Typography>
                        <Box sx={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 2 }}>
                            {LANGUAGES.slice(0, 4).map((lang) => (
                                <TextField
                                    key={lang}
                                    label={`Hint (${LANGUAGE_NAMES[lang]})`}
                                    value={form.hint?.[lang] || ''}
                                    onChange={(e) => updateHint(lang, e.target.value)}
                                    size="small"
                                />
                            ))}
                        </Box>

                        <FormControlLabel
                            control={
                                <Switch
                                    checked={form.requires_consent}
                                    onChange={(e) => setForm({ ...form, requires_consent: e.target.checked })}
                                />
                            }
                            label="Requires Consent"
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
