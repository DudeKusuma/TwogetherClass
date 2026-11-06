<script setup>
import { computed, onMounted, onUnmounted, reactive, ref, watch } from 'vue'
import { Plus, X, ClipboardList, Clock3, CheckCircle2, Bell, Pencil, Trash2, Check, ChevronRight } from 'lucide-vue-next'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/useAuthStore'
import { subjects } from '@/data/subjects'

const auth = useAuthStore()
const tasks = ref([])
const requests = ref([])
const myRequests = ref([])
const loading = ref(true)
const error = ref('')
const selected = ref(null)
const modal = ref('')
const rejectReasons = reactive({})
const form = reactive({ subject_key: 'matematika', title: '', description: '', assigned_date: new Date().toISOString().slice(0,10), deadline: '' })
let channel
const subjectList = Object.values(subjects)
const grouped = computed(() => subjectList.map(s => ({ ...s, tasks: tasks.value.filter(t => t.subject_key === s.key) })))
const pendingCount = computed(() => requests.value.length)
const overdueLabel = (task) => task.deadline && task.deadline < new Date().toISOString().slice(0,10)

async function load() {
 if (!supabase) { error.value='Supabase belum terhubung.'; loading.value=false; return }
 loading.value=true
 const [taskRes, activityRes, mineRes] = await Promise.all([
  supabase.from('class_tasks').select('*, creator:profiles!class_tasks_created_by_fkey(display_name)').order('deadline',{ascending:true,nullsFirst:false}),
  supabase.from('subject_activities').select('id,subject,type,title,notes,date,created_at').eq('type','tugas').order('date',{ascending:true,nullsFirst:false}),
  supabase.from('task_requests').select('*').eq('requester_id',auth.user.id).order('created_at',{ascending:false}).limit(15)
 ])
 if(taskRes.error) error.value=taskRes.error.message
 if(activityRes.error) error.value=activityRes.error.message
 const directTasks = (taskRes.data||[]).map(t=>({...t, source:'class_task'}))
 const adminActivities = (activityRes.data||[]).map(a=>({id:`activity-${a.id}`,subject_key:a.subject,title:a.title,description:a.notes||'',assigned_date:a.date,deadline:a.date,created_at:a.created_at,creator:{display_name:'Admin'},source:'admin_activity'}))
 tasks.value=[...directTasks,...adminActivities].sort((a,b)=>(a.deadline||'9999').localeCompare(b.deadline||'9999'))
 myRequests.value=mineRes.data||[]
 if(auth.isAdmin) { const {data, error:e}=await supabase.from('task_requests').select('*, requester:profiles!task_requests_requester_id_fkey(display_name)').eq('status','pending').order('created_at'); if(e) error.value=e.message; requests.value=data||[] }
 loading.value=false
}
function openCreate(){ Object.assign(form,{subject_key:'matematika',title:'',description:'',assigned_date:new Date().toISOString().slice(0,10),deadline:''}); selected.value=null; modal.value='form' }
function openEdit(task){ Object.assign(form,{subject_key:task.subject_key,title:task.title,description:task.description,assigned_date:task.assigned_date,deadline:task.deadline||''}); selected.value=task; modal.value='form' }
async function saveTask(){
 error.value=''; if(!form.title.trim()) {error.value='Judul tugas wajib diisi.';return}
 const payload={...form,deadline:form.deadline||null}
 if(auth.isAdmin){
  const q=selected.value ? supabase.from('class_tasks').update(payload).eq('id',selected.value.id) : supabase.from('class_tasks').insert({...payload,created_by:auth.user.id})
  const {error:e}=await q; if(e){error.value=e.message;return}
 } else if (!selected.value) {
  const {error:e}=await supabase.from('task_requests').insert({requester_id:auth.user.id,request_type:'add',payload}); if(e){error.value=e.message;return}
 } else {
  const {error:e}=await supabase.from('task_requests').insert({requester_id:auth.user.id,task_id:selected.value.id,request_type:'edit',payload}); if(e){error.value=e.message;return}
 }
 modal.value=''; await load()
}
async function requestDelete(task){ if(!confirm(`Ajukan penghapusan tugas "${task.title}"?`)) return
 const {error:e}=await supabase.from('task_requests').insert({requester_id:auth.user.id,task_id:task.id,request_type:'delete',payload:{title:task.title}}); if(e) error.value=e.message; else await load() }
async function review(req,status){ const reason=(rejectReasons[req.id]||'').trim(); if(status==='rejected'&&!reason){error.value='Alasan penolakan wajib diisi.';return}
 const {error:e}=await supabase.from('task_requests').update({status,rejection_reason:status==='rejected'?reason:null,reviewed_by:auth.user.id,reviewed_at:new Date().toISOString()}).eq('id',req.id); if(e)error.value=e.message; else await load() }
function requestText(r){return ({add:'Tambah tugas',edit:'Edit tugas',delete:'Hapus tugas'})[r.request_type]}
watch(()=>auth.isAdmin,load)
onMounted(()=>{load(); if(supabase) channel=supabase.channel('task-requests-live').on('postgres_changes',{event:'*',schema:'public',table:'task_requests'},load).subscribe()})
onUnmounted(()=>{if(channel&&supabase)supabase.removeChannel(channel)})
</script>

<template>
<section class="tasks-page">
 <header class="page-head"><span class="page-head__eyebrow">Twogether Class · XI B2</span><div class="task-heading"><div><h1 class="page-head__title">Daftar Tugas</h1><p class="page-head__desc">Semua tugas tersusun berdasarkan mata pelajaran.</p></div><button v-if="auth.isAdmin" class="approval-button" @click="modal='requests'" aria-label="Pengajuan tugas"><Bell :size="18"/><b v-if="pendingCount">{{pendingCount}}</b></button></div></header>
 <p v-if="error" class="task-notice">{{error}}</p>
 <div v-if="loading" class="task-empty">Memuat tugas...</div>
 <div v-else-if="!grouped.length" class="task-empty"><ClipboardList :size="30"/><b>Belum ada tugas</b><span>Tugas kelas akan muncul di sini setelah ditambahkan.</span></div>
 <div class="subject-task-list">
  <button v-for="s in grouped" :key="s.key" class="subject-task-card" @click="selected={...s};modal='subject'">
   <span class="subject-icon" :style="{background:s.accent}"><img :src="s.icon" :alt="s.name"/></span><span class="subject-info"><b>{{s.name}}</b><small>{{s.tasks.length}} tugas</small><small v-if="s.tasks[0]" class="task-preview">{{s.tasks[0].title}}</small></span><ChevronRight :size="19"/>
  </button>
 </div>
 <section v-if="myRequests.length" class="my-submissions"><h2>Status pengajuan saya</h2><div v-for="r in myRequests" :key="r.id" class="submission-row"><span>{{requestText(r)}}</span><b :class="'status-'+r.status">{{r.status==='pending'?'Menunggu':r.status==='approved'?'Disetujui':'Ditolak'}}</b></div></section>
 <button class="fab" aria-label="Tambah tugas" @click="openCreate"><Plus/></button>
</section>
<div v-if="modal" class="modal-bg" @click.self="modal=''"><section class="task-modal">
 <header><h2>{{modal==='form'?(selected?'Ajukan perubahan tugas':'Tambah tugas'):modal==='requests'?'Persetujuan tugas':modal==='subject'?selected.name:'Detail tugas'}}</h2><button class="close" @click="modal=''"><X/></button></header>
 <template v-if="modal==='form'"><label>Mata pelajaran<select v-model="form.subject_key"><option v-for="s in subjectList" :key="s.key" :value="s.key">{{s.name}}</option></select></label><label>Judul tugas<input v-model="form.title" maxlength="140" placeholder="Contoh: Latihan Bab 3"/></label><label>Deskripsi / instruksi<textarea v-model="form.description" rows="3" placeholder="Detail tugas..."/></label><div class="form-grid"><label>Tanggal diberikan<input v-model="form.assigned_date" type="date"/></label><label>Deadline<input v-model="form.deadline" type="date"/></label></div><p v-if="!auth.isAdmin" class="helper">Tugas yang kamu ajukan akan muncul setelah disetujui admin. Kamu bisa memantau statusnya di bagian Status pengajuan saya.</p><button class="primary" @click="saveTask">{{auth.isAdmin?'Simpan tugas':selected?'Kirim perubahan':'Ajukan tugas'}}</button></template>
 <template v-else-if="modal==='subject'"><div v-if="!selected.tasks.length" class="task-empty">Belum ada tugas untuk mapel ini.</div><article v-for="t in selected.tasks" :key="t.id" class="task-item"><div class="task-item-top"><b>{{t.title}}</b><span v-if="overdueLabel(t)" class="done-label"><CheckCircle2 :size="14"/> Selesai</span><span v-else-if="t.deadline" class="deadline-label"><Clock3 :size="14"/> Deadline · {{new Date(t.deadline+'T00:00:00').toLocaleDateString('id-ID',{day:'numeric',month:'short',year:'numeric'})}}</span></div><p>{{t.description||'Tidak ada deskripsi.'}}</p><small>Dibuat oleh {{t.creator?.display_name||'Admin'}} · {{new Date(t.created_at).toLocaleDateString('id-ID')}}</small><div v-if="t.source==='class_task' && (auth.isAdmin||t.created_by===auth.user.id)" class="task-actions"><button @click="openEdit(t)"><Pencil :size="15"/> Edit</button><button @click="auth.isAdmin ? supabase.from('class_tasks').delete().eq('id',t.id).then(load) : requestDelete(t)"><Trash2 :size="15"/> Hapus</button></div></article></template>
 <template v-else-if="modal==='requests'"><div v-if="!requests.length" class="task-empty">Tidak ada pengajuan yang menunggu.</div><article v-for="r in requests" :key="r.id" class="request-item"><b>{{requestText(r)}} · {{r.requester?.display_name||'Siswa'}}</b><p>{{r.payload.title||r.payload.subject_key}} <span v-if="r.request_type==='add'">· {{subjectList.find(s=>s.key===r.payload.subject_key)?.name||r.payload.subject_key}}</span></p><div v-if="r.request_type==='delete'" class="helper">Permintaan menghapus tugas: {{r.payload.title}}</div><label v-if="r.status==='pending'">Alasan penolakan (wajib jika ditolak)<input v-model="rejectReasons[r.id]" placeholder="Tuliskan alasan..."/></label><div class="task-actions"><button class="approve" @click="review(r,'approved')"><Check :size="15"/> Setujui</button><button class="reject" @click="review(r,'rejected')">Tolak</button></div></article></template>
 </section></div>
</template>

<style scoped>
.task-heading{display:flex;align-items:center;justify-content:space-between;gap:12px}.approval-button{position:relative;border:1px solid var(--c-border);background:white;border-radius:14px;width:44px;height:44px;display:grid;place-items:center}.approval-button b{position:absolute;right:-5px;top:-5px;background:#e5484d;color:white;border-radius:20px;padding:2px 6px;font-size:10px}.subject-task-list{display:grid;gap:12px}.subject-task-card{width:100%;display:flex;align-items:center;gap:14px;text-align:left;padding:14px 16px;background:white;border:1px solid var(--c-border);border-radius:20px;box-shadow:var(--shadow-sm);color:var(--c-text)}.subject-icon{width:52px;height:52px;border-radius:16px;display:grid;place-items:center;flex-shrink:0}.subject-icon img{width:37px;height:37px;object-fit:contain}.subject-info{display:grid;gap:3px;flex:1;min-width:0}.subject-info b{font-size:15px}.subject-info small{color:var(--c-text-muted);font-size:12px}.task-preview{white-space:nowrap;overflow:hidden;text-overflow:ellipsis}.fab{position:fixed;right:22px;bottom:calc(var(--nav-h) + 30px + env(safe-area-inset-bottom));width:56px;height:56px;border:0;border-radius:50%;background:var(--c-primary);color:white;display:grid;place-items:center;box-shadow:var(--shadow-primary);z-index:35}.task-empty{display:grid;justify-items:center;gap:9px;padding:35px 18px;color:var(--c-text-muted);text-align:center}.task-empty b{color:var(--c-text)}.my-submissions{margin-top:22px;background:white;border:1px solid var(--c-border);border-radius:18px;padding:16px}.my-submissions h2{font-size:15px;margin-bottom:10px}.submission-row{display:flex;justify-content:space-between;padding:9px 0;border-top:1px solid var(--c-border);font-size:13px}.status-pending{color:#a66a00}.status-approved{color:#17834c}.status-rejected{color:#d23e46}.modal-bg{position:fixed;inset:0;background:#1e293b66;z-index:100;display:flex;align-items:flex-end;justify-content:center;padding:12px}.task-modal{width:min(100%,620px);max-height:88vh;overflow:auto;background:#fff;border-radius:24px;padding:20px;box-shadow:var(--shadow-lg)}.task-modal header{display:flex;align-items:center;justify-content:space-between;margin-bottom:18px}.task-modal h2{font-size:18px}.close{border:0;background:#f2f4f8;border-radius:50%;width:36px;height:36px;display:grid;place-items:center}.task-modal label{display:grid;gap:6px;font-size:12px;font-weight:700;margin:12px 0}.task-modal input,.task-modal textarea,.task-modal select{width:100%;padding:11px 12px;border:1px solid var(--c-border);border-radius:12px;font:inherit;font-size:14px;background:#fff}.form-grid{display:grid;grid-template-columns:1fr 1fr;gap:10px}.helper{font-size:12px;color:var(--c-text-muted);margin:12px 0}.primary{width:100%;border:0;border-radius:13px;background:var(--c-primary);color:white;padding:13px;font-weight:800;margin-top:10px}.task-item,.request-item{padding:14px 0;border-top:1px solid var(--c-border)}.task-item p,.request-item p{font-size:13px;color:var(--c-text-muted);margin:8px 0}.task-item small{font-size:11px;color:var(--c-text-soft)}.task-item-top{display:flex;justify-content:space-between;gap:8px;align-items:center}.deadline-label,.done-label{font-size:11px;display:flex;align-items:center;gap:4px;white-space:nowrap}.deadline-label{color:#ad7200}.done-label{color:#16834c}.task-actions{display:flex;gap:8px;margin-top:10px}.task-actions button{display:flex;align-items:center;gap:5px;border:1px solid var(--c-border);border-radius:10px;background:white;padding:7px 10px;font-size:12px}.task-actions .approve{color:#16834c}.task-actions .reject{color:#cf3f48}.task-notice{background:#fff0f0;color:#b42b36;padding:10px 12px;border-radius:12px;font-size:13px}@media(min-width:700px){.subject-task-card{padding:16px 20px}.modal-bg{align-items:center}.task-modal{max-height:85vh}}
</style>
