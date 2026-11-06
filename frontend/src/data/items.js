// Jadwal resmi XI-B2, siklus mingguan Senin-Sabtu. Jam ke-0 diabaikan.
export const TIMETABLE_IS_DUMMY = false
const lesson = (subject, start, end) => ({ type: 'lesson', subject, start, end, teacher: null, assignment: null })
const rest = (start, end) => ({ type: 'break', label: 'Istirahat', start, end })
export const dummyTimetable = {
  1: [lesson('matematikaLanjut','07:30','10:45'), lesson('sejarah','10:45','12:15'), rest('12:15','12:30'), lesson('ppkn','12:30','14:00')],
  2: [lesson('ingg','07:30','09:00'), lesson('kimia','09:00','10:45'), lesson('bahasaIndonesia','10:45','12:15'), rest('12:15','12:30'), lesson('matematika','12:30','14:00')],
  3: [lesson('pkwu','07:30','09:00'), lesson('bahasaInggris','09:00','10:45'), lesson('biologi','10:45','12:15'), rest('12:15','12:30'), lesson('matematikaLanjut','12:30','14:00')],
  4: [lesson('matematika','07:30','09:00'), lesson('bahasaBali','09:00','10:45'), lesson('bahasaIndonesia','10:45','12:15'), rest('12:15','12:30'), lesson('seni','12:30','14:00')],
  5: [lesson('agama','07:30','09:00'), lesson('bahasaInggris','09:00','09:45'), rest('09:45','10:00'), lesson('biologi','10:00','11:30'), lesson('kimia','11:30','14:00')],
  6: [lesson('biologi','07:30','08:15'), lesson('ingg','08:15','10:45')]
}
