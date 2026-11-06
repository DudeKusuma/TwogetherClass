import calculator from '@/assets/icons/calculator.png'
import compass from '@/assets/icons/compass.png'
import englishBook from '@/assets/icons/english-book.png'
import craftTools from '@/assets/icons/craft-tools.png'
import handsHeart from '@/assets/icons/hands-heart.png'
import erlenmeyerFlask from '@/assets/icons/erlenmeyer-flask.png'
import balineseManuscript from '@/assets/icons/balinese-manuscript.png'
import microscope from '@/assets/icons/microscope.png'
import hourglass from '@/assets/icons/hourglass.png'
import indonesianBook from '@/assets/icons/indonesian-book.png'
import paintbrush from '@/assets/icons/paintbrush.png'
import balanceScales from '@/assets/icons/balance-scales.png'
import globe from '@/assets/icons/globe.png'

// Subject names and their supplied icons (exact mapping from the brief).
export const subjects = {
  matematika: { key: 'matematika', name: 'Matematika', icon: calculator, accent: 'var(--c-pink)' },
  matematikaLanjut: { key: 'matematikaLanjut', name: 'Matematika Lanjut', icon: compass, accent: 'var(--c-mint)' },
  bahasaInggris: { key: 'bahasaInggris', name: 'Bahasa Inggris', icon: englishBook, accent: 'var(--c-blue-soft)' },
  pkwu: { key: 'pkwu', name: 'PKWU', icon: craftTools, accent: 'var(--c-yellow)' },
  agama: { key: 'agama', name: 'Agama BP', icon: handsHeart, accent: 'var(--c-pink)' },
  kimia: { key: 'kimia', name: 'Kimia', icon: erlenmeyerFlask, accent: 'var(--c-blue-soft)' },
  bahasaBali: { key: 'bahasaBali', name: 'Bahasa Bali', icon: balineseManuscript, accent: 'var(--c-peach)' },
  biologi: { key: 'biologi', name: 'Biologi', icon: microscope, accent: 'var(--c-mint)' },
  sejarah: { key: 'sejarah', name: 'Sejarah', icon: hourglass, accent: 'var(--c-yellow)' },
  bahasaIndonesia: { key: 'bahasaIndonesia', name: 'Bahasa Indonesia', icon: indonesianBook, accent: 'var(--c-lavender)' },
  seni: { key: 'seni', name: 'Seni', icon: paintbrush, accent: 'var(--c-pink)' },
  ppkn: { key: 'ppkn', name: 'PPKN', icon: balanceScales, accent: 'var(--c-lavender)' },
  ingg: { key: 'ingg', name: 'INGG', icon: globe, accent: 'var(--c-blue-soft)' }
}
