import { Close as CloseIcon, Search as SearchIcon } from '@mui/icons-material';
import {
    Box,
    Button,
    IconButton,
    InputAdornment,
    Popover,
    TextField,
    Typography,
} from '@mui/material';
import { useCallback, useRef, useState } from 'react';

// Common emojis organized by category
const EMOJI_DATA = {
    '🙂': ['😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂', '🙂', '😊', '😇', '🥰', '😍', '🤩', '😘', '😗', '😚', '😋', '😛', '😜', '🤪', '😝', '🤑', '🤗', '🤭', '🤫', '🤔', '🤐', '🤨', '😐', '😑', '😶', '😏', '😒', '🙄', '😬', '🤥', '😌', '😔', '😪', '🤤', '😴', '😷', '🤒', '🤕', '🤢', '🤮', '🤧', '🥵', '🥶', '🥴', '😵', '🤯', '🤠', '🥳', '😎', '🤓', '🧐'],
    '👋': ['👋', '🤚', '🖐️', '✋', '🖖', '👌', '🤌', '🤏', '✌️', '🤞', '🤟', '🤘', '🤙', '👈', '👉', '👆', '🖕', '👇', '☝️', '👍', '👎', '✊', '👊', '🤛', '🤜', '👏', '🙌', '👐', '🤲', '🤝', '🙏', '✍️', '💪'],
    '🧒': ['👶', '👧', '🧒', '👦', '👩', '🧑', '👨', '👩‍🦱', '🧑‍🦱', '👨‍🦱', '👩‍🦰', '🧑‍🦰', '👨‍🦰', '👱‍♀️', '👱', '👱‍♂️', '👩‍🦳', '🧑‍🦳', '👨‍🦳', '👩‍🦲', '🧑‍🦲', '👨‍🦲', '🧔', '👵', '🧓', '👴', '👲', '👳‍♀️', '👳', '👳‍♂️', '🧕', '👮‍♀️', '👮', '👮‍♂️', '👷‍♀️', '👷', '👷‍♂️', '💂‍♀️', '💂', '💂‍♂️', '🕵️‍♀️', '🕵️', '🕵️‍♂️'],
    '🐱': ['🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', '🐻‍❄️', '🐨', '🐯', '🦁', '🐮', '🐷', '🐽', '🐸', '🐵', '🙈', '🙉', '🙊', '🐒', '🐔', '🐧', '🐦', '🐤', '🐣', '🐥', '🦆', '🦅', '🦉', '🦇', '🐺', '🐗', '🐴', '🦄', '🐝', '🐛', '🦋', '🐌', '🐞', '🐜', '🦟', '🦗', '🕷️', '🦂', '🐢', '🐍', '🦎', '🦖', '🦕', '🐙', '🦑', '🦐', '🦞', '🦀', '🐡', '🐠', '🐟', '🐬', '🐳', '🐋', '🦈', '🐊'],
    '🍎': ['🍎', '🍐', '🍊', '🍋', '🍌', '🍉', '🍇', '🍓', '🫐', '🍈', '🍒', '🍑', '🥭', '🍍', '🥥', '🥝', '🍅', '🍆', '🥑', '🥦', '🥬', '🥒', '🌶️', '🫑', '🌽', '🥕', '🫒', '🧄', '🧅', '🥔', '🍠', '🥐', '🥯', '🍞', '🥖', '🥨', '🧀', '🥚', '🍳', '🧈', '🥞', '🧇', '🥓', '🥩', '🍗', '🍖', '🌭', '🍔', '🍟', '🍕', '🫓', '🥪', '🥙', '🧆', '🌮', '🌯', '🫔', '🥗', '🥘', '🫕', '🥫', '🍝'],
    '⚽': ['⚽', '🏀', '🏈', '⚾', '🥎', '🎾', '🏐', '🏉', '🥏', '🎱', '🪀', '🏓', '🏸', '🏒', '🏑', '🥍', '🏏', '🪃', '🥅', '⛳', '🪁', '🏹', '🎣', '🤿', '🥊', '🥋', '🎽', '🛹', '🛼', '🛷', '⛸️', '🥌', '🎿', '⛷️', '🏂', '🪂', '🏋️', '🤼', '🤸', '🤺', '⛹️', '🤾', '🏌️', '🏇', '🧘', '🏄', '🏊', '🤽', '🚣', '🧗', '🚵', '🚴', '🎪', '🎭', '🎨', '🎬', '🎤', '🎧', '🎼', '🎹', '🥁', '🎷', '🎺', '🎸', '🪕', '🎻'],
    '🚎': ['🚗', '🚕', '🚙', '🚌', '🚎', '🏎️', '🚓', '🚑', '🚒', '🚐', '🛻', '🚚', '🚛', '🚜', '🏍️', '🛵', '🚲', '🛴', '🚨', '🚔', '🚍', '🚘', '🚖', '🚡', '🚠', '🚟', '🚃', '🚋', '🚞', '🚝', '🚄', '🚅', '🚈', '🚂', '🚆', '🚇', '🚊', '🚉', '✈️', '🛫', '🛬', '🛩️', '💺', '🛰️', '🚀', '🛸', '🚁', '🛶', '⛵', '🚤', '🛥️', '🛳️', '⛴️', '🚢', '🗼', '🏰', '🏯', '🏟️', '🎡', '🎢', '🎠'],
    '💻': ['⌚', '📱', '📲', '💻', '⌨️', '🖥️', '🖨️', '🖱️', '🖲️', '🕹️', '🗜️', '💽', '💾', '💿', '📀', '📼', '📷', '📸', '📹', '🎥', '📽️', '🎞️', '📞', '☎️', '📟', '📠', '📺', '📻', '🎙️', '🎚️', '🎛️', '🧭', '⏱️', '⏲️', '⏰', '🕰️', '⌛', '⏳', '📡', '🔋', '🔌', '💡', '🔦', '🕯️', '🪔', '🧯', '🛢️', '💸', '💵', '💴', '💶', '💷', '🪙', '💰', '💳', '💎', '⚖️', '🪜', '🧰', '🪛', '🔧', '🔨', '⚒️', '🛠️', '⛏️', '🪚', '🔩', '⚙️'],
    '❤️': ['❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '🤎', '💔', '❣️', '💕', '💞', '💓', '💗', '💖', '💘', '💝', '💟', '☮️', '✝️', '☪️', '🕉️', '☸️', '✡️', '🔯', '🕎', '☯️', '☦️', '🛐', '⛎', '♈', '♉', '♊', '♋', '♌', '♍', '♎', '♏', '♐', '♑', '♒', '♓', '🆔', '⚛️', '🉑', '☢️', '☣️', '📴', '📳', '🈶', '🈚', '🈸', '🈺', '🈷️', '✴️', '🆚', '💮', '🉐', '㊙️', '㊗️', '🈴', '🈵', '🈹', '🈲', '🅰️', '🅱️', '🆎', '🆑', '🅾️', '🆘', '❌', '⭕', '🛑', '⛔', '📛', '🚫', '💯', '💢', '♨️', '🚷', '🚯', '🚳', '🚱', '🔞', '📵', '🚭', '❗', '❕', '❓', '❔', '‼️', '⁉️', '🔅', '🔆', '〽️', '⚠️', '🚸', '🔱', '⚜️', '🔰', '♻️', '✅', '🈯', '💹', '❇️', '✳️', '❎', '🌐', '💠', 'Ⓜ️', '🌀', '💤', '🏧', '🚾', '♿', '🅿️', '🛗', '🈳', '🈂️', '🛂', '🛃', '🛄', '🛅', '🚹', '🚺', '🚼', '⚧️', '🚻', '🚮', '🎦', '📶', '🈁', '🔣', 'ℹ️', '🔤', '🔡', '🔠', '🆖', '🆗', '🆙', '🆒', '🆕', '🆓', '0️⃣', '1️⃣', '2️⃣', '3️⃣', '4️⃣', '5️⃣', '6️⃣', '7️⃣', '8️⃣', '9️⃣', '🔟', '🔢', '#️⃣', '*️⃣', '⏏️', '▶️', '⏸️', '⏯️', '⏹️', '⏺️', '⏭️', '⏮️', '⏩', '⏪', '⏫', '⏬', '◀️', '🔼', '🔽', '➡️', '⬅️', '⬆️', '⬇️', '↗️', '↘️', '↙️', '↖️', '↕️', '↔️', '↪️', '↩️', '⤴️', '⤵️', '🔀', '🔁', '🔂', '🔄', '🔃', '🎵', '🎶', '➕', '➖', '➗', '✖️', '🟰', '♾️', '💲', '💱', '™️', '©️', '®️', '〰️', '➰', '➿', '🔚', '🔙', '🔛', '🔝', '🔜', '✔️', '☑️', '🔘', '🔴', '🟠', '🟡', '🟢', '🔵', '🟣', '⚫', '⚪', '🟤', '🔺', '🔻', '🔸', '🔹', '🔶', '🔷', '🔳', '🔲', '▪️', '▫️', '◾', '◽', '◼️', '◻️', '🟥', '🟧', '🟨', '🟩', '🟦', '🟪', '⬛', '⬜', '🟫', '🔈', '🔇', '🔉', '🔊', '🔔', '🔕', '📣', '📢', '👁️‍🗨️', '💬', '💭', '🗯️', '♠️', '♣️', '♥️', '♦️', '🃏', '🎴', '🀄', '🕐', '🕑', '🕒', '🕓', '🕔', '🕕', '🕖', '🕗', '🕘', '🕙', '🕚', '🕛', '🕜', '🕝', '🕞', '🕟', '🕠', '🕡', '🕢', '🕣', '🕤', '🕥', '🕦', '🕧'],
    '🚩': ['🏳️', '🏴', '🏁', '🚩', '🏳️‍🌈', '🏳️‍⚧️', '🇺🇳', '🇦🇫', '🇦🇱', '🇩🇿', '🇦🇸', '🇦🇩', '🇦🇴', '🇦🇮', '🇦🇶', '🇦🇬', '🇦🇷', '🇦🇲', '🇦🇼', '🇦🇺', '🇦🇹', '🇦🇿', '🇧🇸', '🇧🇭', '🇧🇩', '🇧🇧', '🇧🇾', '🇧🇪', '🇧🇿', '🇧🇯', '🇧🇲', '🇧🇹', '🇧🇴', '🇧🇦', '🇧🇼', '🇧🇷', '🇮🇴', '🇻🇬', '🇧🇳', '🇧🇬', '🇧🇫', '🇧🇮', '🇰🇭', '🇨🇲', '🇨🇦', '🇮🇨', '🇨🇻', '🇧🇶', '🇰🇾', '🇨🇫', '🇹🇩', '🇨🇱', '🇨🇳', '🇨🇽', '🇨🇨', '🇨🇴', '🇰🇲', '🇨🇬', '🇨🇩', '🇨🇰', '🇨🇷', '🇨🇮', '🇭🇷', '🇨🇺', '🇨🇼', '🇨🇾', '🇨🇿', '🇩🇰', '🇩🇯', '🇩🇲', '🇩🇴', '🇪🇨', '🇪🇬', '🇸🇻', '🇬🇶', '🇪🇷', '🇪🇪', '🇸🇿', '🇪🇹', '🇪🇺', '🇫🇰', '🇫🇴', '🇫🇯', '🇫🇮', '🇫🇷', '🇬🇫', '🇵🇫', '🇹🇫', '🇬🇦', '🇬🇲', '🇬🇪', '🇩🇪', '🇬🇭', '🇬🇮', '🇬🇷', '🇬🇱', '🇬🇩', '🇬🇵', '🇬🇺', '🇬🇹', '🇬🇬', '🇬🇳', '🇬🇼', '🇬🇾', '🇭🇹', '🇭🇳', '🇭🇰', '🇭🇺', '🇮🇸', '🇮🇳', '🇮🇩', '🇮🇷', '🇮🇶', '🇮🇪', '🇮🇲', '🇮🇱', '🇮🇹', '🇯🇲', '🇯🇵', '🎌', '🇯🇪', '🇯🇴', '🇰🇿', '🇰🇪', '🇰🇮', '🇽🇰', '🇰🇼', '🇰🇬', '🇱🇦', '🇱🇻', '🇱🇧', '🇱🇸', '🇱🇷', '🇱🇾', '🇱🇮', '🇱🇹', '🇱🇺', '🇲🇴', '🇲🇬', '🇲🇼', '🇲🇾', '🇲🇻', '🇲🇱', '🇲🇹', '🇲🇭', '🇲🇶', '🇲🇷', '🇲🇺', '🇾🇹', '🇲🇽', '🇫🇲', '🇲🇩', '🇲🇨', '🇲🇳', '🇲🇪', '🇲🇸', '🇲🇦', '🇲🇿', '🇲🇲', '🇳🇦', '🇳🇷', '🇳🇵', '🇳🇱', '🇳🇨', '🇳🇿', '🇳🇮', '🇳🇪', '🇳🇬', '🇳🇺', '🇳🇫', '🇰🇵', '🇲🇰', '🇲🇵', '🇳🇴', '🇴🇲', '🇵🇰', '🇵🇼', '🇵🇸', '🇵🇦', '🇵🇬', '🇵🇾', '🇵🇪', '🇵🇭', '🇵🇳', '🇵🇱', '🇵🇹', '🇵🇷', '🇶🇦', '🇷🇪', '🇷🇴', '🇷🇺', '🇷🇼', '🇼🇸', '🇸🇲', '🇸🇹', '🇸🇦', '🇸🇳', '🇷🇸', '🇸🇨', '🇸🇱', '🇸🇬', '🇸🇽', '🇸🇰', '🇸🇮', '🇬🇸', '🇸🇧', '🇸🇴', '🇿🇦', '🇰🇷', '🇸🇸', '🇪🇸', '🇱🇰', '🇧🇱', '🇸🇭', '🇰🇳', '🇱🇨', '🇵🇲', '🇻🇨', '🇸🇩', '🇸🇷', '🇸🇪', '🇨🇭', '🇸🇾', '🇹🇼', '🇹🇯', '🇹🇿', '🇹🇭', '🇹🇱', '🇹🇬', '🇹🇰', '🇹🇴', '🇹🇹', '🇹🇳', '🇹🇷', '🇹🇲', '🇹🇨', '🇹🇻', '🇻🇮', '🇺🇬', '🇺🇦', '🇦🇪', '🇬🇧', '🏴󠁧󠁢󠁥󠁮󠁧󠁿', '🏴󠁧󠁢󠁳󠁣󠁴󠁿', '🏴󠁧󠁢󠁷󠁬󠁳󠁿', '🇺🇸', '🇺🇾', '🇺🇿', '🇻🇺', '🇻🇦', '🇻🇪', '🇻🇳', '🇼🇫', '🇪🇭', '🇾🇪', '🇿🇲', '🇿🇼'],
};

// Frequently used emojis for quick access
const FREQUENT_EMOJIS = ['😀', '😂', '❤️', '👍', '🎉', '🔥', '✨', '💯', '🎮', '🎭', '🎪', '🎨', '🎬', '🎤', '🎧', '🎵', '🏆', '⭐', '💡', '📝', '🔔', '⚡', '💪', '🙌', '👋', '🤔', '😎', '🥳', '😍', '🤩'];

interface EmojiPickerProps {
    value: string;
    onChange: (emoji: string) => void;
}

export default function EmojiPicker({ value, onChange }: EmojiPickerProps) {
    const [anchorEl, setAnchorEl] = useState<HTMLElement | null>(null);
    const [search, setSearch] = useState('');
    const [selectedCategory, setSelectedCategory] = useState<string>('🕐');
    const [focusedIndex, setFocusedIndex] = useState<number>(-1);
    const gridRef = useRef<HTMLDivElement>(null);

    const handleOpen = (event: React.MouseEvent<HTMLElement>) => {
        setAnchorEl(event.currentTarget);
        setFocusedIndex(-1);
    };

    const handleClose = () => {
        setAnchorEl(null);
        setSearch('');
        setFocusedIndex(-1);
    };

    const handleSelect = useCallback((emoji: string) => {
        onChange(emoji);
        setAnchorEl(null);
        setSearch('');
        setFocusedIndex(-1);
    }, [onChange]);

    const open = Boolean(anchorEl);

    // Filter emojis based on search
    const getFilteredEmojis = useCallback(() => {
        if (search) {
            const allEmojis = Object.values(EMOJI_DATA).flat();
            // Simple search - just return all emojis that include the search term in their category
            // or match the emoji itself
            return allEmojis.filter((emoji) => emoji.includes(search));
        }
        if (selectedCategory === '🕐') {
            return FREQUENT_EMOJIS;
        }
        return EMOJI_DATA[selectedCategory as keyof typeof EMOJI_DATA] || [];
    }, [search, selectedCategory]);

    const categories = ['🕐', ...Object.keys(EMOJI_DATA)];
    const filteredEmojis = getFilteredEmojis();

    // Handle keyboard navigation in emoji grid
    const handleKeyDown = useCallback((event: React.KeyboardEvent) => {
        const emojisPerRow = 8;
        const currentEmojis = getFilteredEmojis();
        const maxIndex = Math.min(currentEmojis.length - 1, 199);

        switch (event.key) {
            case 'ArrowRight':
                event.preventDefault();
                setFocusedIndex((prev) => Math.min(prev + 1, maxIndex));
                break;
            case 'ArrowLeft':
                event.preventDefault();
                setFocusedIndex((prev) => Math.max(prev - 1, 0));
                break;
            case 'ArrowDown':
                event.preventDefault();
                setFocusedIndex((prev) => Math.min(prev + emojisPerRow, maxIndex));
                break;
            case 'ArrowUp':
                event.preventDefault();
                setFocusedIndex((prev) => Math.max(prev - emojisPerRow, 0));
                break;
            case 'Enter':
            case ' ':
                event.preventDefault();
                if (focusedIndex >= 0 && focusedIndex <= maxIndex) {
                    handleSelect(currentEmojis[focusedIndex]);
                }
                break;
            case 'Escape':
                handleClose();
                break;
        }
    }, [getFilteredEmojis, focusedIndex, handleSelect]);

    // Category names for accessibility
    const categoryNames: Record<string, string> = {
        '🕐': 'Frequently used',
        '🙂': 'Smileys & Emotion',
        '👋': 'People & Body',
        '🧒': 'People',
        '🐱': 'Animals & Nature',
        '🍎': 'Food & Drink',
        '⚽': 'Activities',
        '🚎': 'Travel & Places',
        '💻': 'Objects',
        '❤️': 'Symbols',
        '🚩': 'Flags',
    };

    return (
        <>
            <Button
                variant="outlined"
                onClick={handleOpen}
                aria-label={`Select emoji. Current: ${value || 'none'}`}
                aria-haspopup="dialog"
                aria-expanded={open}
                sx={{
                    minWidth: 50,
                    height: 40,
                    fontSize: '1.5rem',
                    borderColor: 'divider',
                }}
            >
                {value || '📝'}
            </Button>

            <Popover
                open={open}
                anchorEl={anchorEl}
                onClose={handleClose}
                anchorOrigin={{
                    vertical: 'bottom',
                    horizontal: 'left',
                }}
                transformOrigin={{
                    vertical: 'top',
                    horizontal: 'left',
                }}
                slotProps={{
                    paper: {
                        role: 'dialog',
                        'aria-label': 'Emoji picker',
                    },
                }}
            >
                <Box sx={{ width: 352, p: 1.5, overflow: 'hidden' }}>
                    {/* Search */}
                    <TextField
                        fullWidth
                        size="small"
                        placeholder="Search emojis..."
                        value={search}
                        onChange={(e) => setSearch(e.target.value)}
                        sx={{ mb: 1.5 }}
                        aria-label="Search emojis"
                        inputProps={{
                            'aria-describedby': 'emoji-search-hint',
                        }}
                        InputProps={{
                            startAdornment: (
                                <InputAdornment position="start">
                                    <SearchIcon fontSize="small" aria-hidden="true" />
                                </InputAdornment>
                            ),
                            endAdornment: search && (
                                <InputAdornment position="end">
                                    <IconButton
                                        size="small"
                                        onClick={() => setSearch('')}
                                        aria-label="Clear search"
                                    >
                                        <CloseIcon fontSize="small" />
                                    </IconButton>
                                </InputAdornment>
                            ),
                        }}
                    />
                    <span id="emoji-search-hint" className="visually-hidden" style={{ position: 'absolute', width: 1, height: 1, overflow: 'hidden' }}>
                        Type to search for emojis
                    </span>

                    {/* Category tabs */}
                    {!search && (
                        <Box
                            sx={{
                                display: 'grid',
                                gridTemplateColumns: 'repeat(11, 1fr)',
                                gap: 0.25,
                                pb: 1,
                                mb: 1,
                                borderBottom: '1px solid',
                                borderColor: 'divider',
                            }}
                            role="tablist"
                            aria-label="Emoji categories"
                        >
                            {categories.map((category) => (
                                <Box
                                    key={category}
                                    onClick={() => setSelectedCategory(category)}
                                    onKeyDown={(e) => {
                                        if (e.key === 'Enter' || e.key === ' ') {
                                            e.preventDefault();
                                            setSelectedCategory(category);
                                        }
                                    }}
                                    role="tab"
                                    tabIndex={selectedCategory === category ? 0 : -1}
                                    aria-selected={selectedCategory === category}
                                    aria-label={categoryNames[category] || category}
                                    sx={{
                                        display: 'flex',
                                        alignItems: 'center',
                                        justifyContent: 'center',
                                        fontSize: '1.25rem',
                                        cursor: 'pointer',
                                        width: 28,
                                        height: 28,
                                        borderRadius: '50%',
                                        bgcolor: selectedCategory === category ? 'primary.main' : 'transparent',
                                        '&:hover': {
                                            bgcolor: selectedCategory === category ? 'primary.main' : 'action.hover',
                                        },
                                        '&:focus': {
                                            outline: '2px solid',
                                            outlineColor: 'primary.main',
                                            outlineOffset: 2,
                                        },
                                    }}
                                >
                                    {category}
                                </Box>
                            ))}
                        </Box>
                    )}

                    {/* Emoji grid */}
                    <Box
                        ref={gridRef}
                        onKeyDown={handleKeyDown}
                        role="grid"
                        aria-label={`${categoryNames[selectedCategory] || 'Emoji'} grid`}
                        tabIndex={0}
                        sx={{
                            display: 'grid',
                            gridTemplateColumns: 'repeat(8, 1fr)',
                            gap: 0.25,
                            maxHeight: 250,
                            overflowY: 'auto',
                            overflowX: 'hidden',
                            '&::-webkit-scrollbar': { width: 6 },
                            '&::-webkit-scrollbar-thumb': { bgcolor: 'divider', borderRadius: 3 },
                            '&:focus': {
                                outline: '2px solid',
                                outlineColor: 'primary.main',
                                outlineOffset: -2,
                            },
                        }}
                    >
                        {filteredEmojis.slice(0, 200).map((emoji, index) => (
                            <Box
                                key={`${emoji}-${index}`}
                                onClick={() => handleSelect(emoji)}
                                onKeyDown={(e) => {
                                    if (e.key === 'Enter' || e.key === ' ') {
                                        e.preventDefault();
                                        handleSelect(emoji);
                                    }
                                }}
                                role="gridcell"
                                tabIndex={focusedIndex === index ? 0 : -1}
                                aria-label={`Select ${emoji}`}
                                sx={{
                                    width: 40,
                                    height: 40,
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'center',
                                    fontSize: '1.5rem',
                                    cursor: 'pointer',
                                    borderRadius: 1,
                                    userSelect: 'none',
                                    fontFamily: '"Apple Color Emoji", "Segoe UI Emoji", "Noto Color Emoji", sans-serif',
                                    bgcolor: focusedIndex === index ? 'action.selected' : 'transparent',
                                    '&:hover': {
                                        bgcolor: 'action.hover',
                                    },
                                    '&:focus': {
                                        outline: '2px solid',
                                        outlineColor: 'primary.main',
                                        outlineOffset: -2,
                                    },
                                }}
                            >
                                {emoji}
                            </Box>
                        ))}
                    </Box>

                    {filteredEmojis.length === 0 && (
                        <Typography color="text.secondary" textAlign="center" py={2}>
                            No emojis found
                        </Typography>
                    )}
                </Box>
            </Popover>
        </>
    );
}
