// Color constants for light and dark modes

export const colors = {
    light: {
        text: '#212529',           // Dark Gray - Main text (readable on light bg)
        primary: '#E63946',        // Red - Buttons, CTAs
        background: '#FFF3E0',     // Light Beige - Overall background
        secondary: '#FFFFFF',      // Soft White - Cards, panels
        accentOrange: '#F77F00',   // Orange - Highlights
        accentYellow: '#FFBE0B',   // Yellow - Badges, promotions
        buttonBg: '#E63946',       // Red - Primary buttons (matches theme)
        buttonText: '#FFFFFF',     // White - Text on red buttons
        // Semantic colors
        success: '#4CAF50',
        danger: '#FF5252',
        // Derived/Utility colors
        bgAlt: '#f1e4d3',
        border: 'rgba(0, 0, 0, 0.08)',
    },
    dark: {
        text: '#EAEAEA',           // Light Gray - Main text
        primary: '#E63946',        // Red - Same primary
        background: '#121212',     // Dark Gray - Main background
        secondary: '#1E1E1E',      // Darker Gray - Cards, panels
        accentOrange: '#F77F00',   // Orange - Highlights
        accentYellow: '#FFBE0B',   // Yellow - Active states
        buttonBg: '#E63946',       // Red - Primary buttons
        buttonText: '#FFFFFF',     // White - Text on red buttons
        // Semantic colors
        success: '#66BB6A',
        danger: '#FF5252',
        // Derived/Utility colors
        bgAlt: '#1a1a1a',
        border: 'rgba(255, 255, 255, 0.1)',
    },
};

// Export individual color palettes for convenience
export const lightColors = colors.light;
export const darkColors = colors.dark;

// Default to light mode
export default colors.light;

/**
 * Applies the selected theme colors to the document root as CSS variables.
 * This ensures all CSS files using var(--color-*) are updated.
 */
export const applyTheme = (mode: 'light' | 'dark' = 'light') => {
    const theme = colors[mode];
    const root = document.documentElement;

    root.style.setProperty('--color-text', theme.text);
    root.style.setProperty('--color-primary', theme.primary);
    root.style.setProperty('--color-background', theme.background);
    root.style.setProperty('--color-secondary', theme.secondary);
    root.style.setProperty('--color-accent-orange', theme.accentOrange);
    root.style.setProperty('--color-accent-yellow', theme.accentYellow);
    root.style.setProperty('--color-button-bg', theme.buttonBg);
    root.style.setProperty('--color-button-text', theme.buttonText);

    root.style.setProperty('--color-success', theme.success);
    root.style.setProperty('--color-danger', theme.danger);

    root.style.setProperty('--color-bg-alt', theme.bgAlt);
    root.style.setProperty('--color-border', theme.border);
};
