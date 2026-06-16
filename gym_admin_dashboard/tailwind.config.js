/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: {
    extend: {
      colors: {
        ink: '#111827',
        muted: '#6B7280',
        gym: {
          50: '#ECFEFF',
          100: '#CFFAFE',
          500: '#06B6D4',
          600: '#0891B2',
          700: '#0E7490',
        },
      },
      boxShadow: {
        soft: '0 18px 50px rgba(8, 47, 73, 0.10)',
      },
    },
  },
  plugins: [],
}
