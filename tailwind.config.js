/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: {
    extend: {
      colors: {
        ink: '#111827',
        muted: '#6B7280',
        gym: {
          50: '#ECFDF5',
          100: '#D1FAE5',
          500: '#10B981',
          600: '#059669',
          700: '#047857',
        },
      },
      boxShadow: {
        soft: '0 16px 40px rgba(17, 24, 39, 0.08)',
      },
    },
  },
  plugins: [],
}
