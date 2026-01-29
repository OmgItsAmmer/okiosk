// Color constants for light and dark modes

export const colors = {
    light: {
        text: '#212529',           // Dark Gray - Main text
        primary: '#E63946',        // Red - Buttons, CTAs
        background: '#FFF3E0',     // Light Beige - Overall background
        secondary: '#FFFFFF',      // Soft White - Cards, panels
        accentOrange: '#F77F00',   // Orange - Highlights
        accentYellow: '#FFBE0B',   // Yellow - Badges, promotions
    },
    dark: {
        text: '#EAEAEA',           // Light Gray - Main text
        primary: '#E63946',        // Red - Same primary
        background: '#121212',     // Dark Gray - Main background
        secondary: '#1E1E1E',      // Darker Gray - Cards, panels
        accentOrange: '#F77F00',   // Orange - Highlights
        accentYellow: '#FFBE0B',   // Yellow - Active states
    },
};

// Export individual color palettes for convenience
export const lightColors = colors.light;
export const darkColors = colors.dark;

// Default to light mode
export default colors.light;
