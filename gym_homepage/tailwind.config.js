/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: {
    extend: {
      colors: {
        brand: {
          primary: '#0AB8CF',
          primaryDim: '#0892A4',
          accent: '#FF6B4A',
          background: '#060E10',
          surface: '#0D1A1E',
          surface2: '#142028',
          surface3: '#1E2E38',
          surfaceHigh: '#2A3E48',
          outline: '#152228',
          outlineStrong: '#1E3040',
          textPrimary: '#F0F4F8',
          textSecondary: '#7A9AAA',
          textTertiary: '#4A6878',
          success: '#22C55E',
          danger: '#FF4C4C',
          warning: '#FFAA00',
          violet: '#9B7BFF',
          blue: '#4C9EFF',
        },
      },
      boxShadow: {
        glow: '0 0 24px rgba(10, 184, 207, 0.25)',
        soft: '0 18px 50px rgba(0, 0, 0, 0.35)',
      },
      animation: {
        'fade-in': 'fadeIn 0.3s ease-out',
        'slide-up': 'slideUp 0.3s ease-out',
      },
      keyframes: {
        fadeIn: { '0%': { opacity: 0 }, '100%': { opacity: 1 } },
        slideUp: { '0%': { opacity: 0, transform: 'translateY(8px)' }, '100%': { opacity: 1, transform: 'translateY(0)' } },
      },
    },
  },
  plugins: [],
}
