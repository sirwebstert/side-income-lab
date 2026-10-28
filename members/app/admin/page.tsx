'use client';
import {useEffect,useState} from 'react';
import Link from 'next/link';
import {db} from '@/lib/supabase';
type Offer={id:string;title:string;description:string;category:string;countries_allowed:string[];status:string};
type Destination={opportunity_id:string;country_code:string;destination_url:string};
type ClickSummary={opportunity_id:string;country_code:string;clicks:number;unique_members:number};
const countries=['ZW','ZA','GB','US','CA'];
export default function Admin(){
 const [authorized,setAuthorized]=useState(false),[loading,setLoading]=useState(true),[error,setError]=useState(''),[notice,setNotice]=useState('');
 const [offers,setOffers]=useState<Offer[]>([]),[destinations,setDestinations]=useState<Destination[]>([]),[members,setMembers]=useState<number|null>(null),[clicks,setClicks]=useState<ClickSummary[]>([]),[analyticsError,setAnalyticsError]=useState('');
 const [saving,setSaving]=useState(false);const [selected,setSelected]=useState(''),[title,setTitle]=useState(''),[description,setDescription]=useState(''),[category,setCategory]=useState('Paid Surveys'),[status,setStatus]=useState('draft'),[allowed,setAllowed]=useState<string[]>(['ZW']),[links,setLinks]=useState<Record<string,string>>({});
 async function refresh(){
  const s=db();
  const [a,b,c,d]=await Promise.all([s.from('opportunities').select('id,title,description,category,countries_allowed,status').order('created_at',{ascending:false}),s.from('opportunity_destinations').select('opportunity_id,country_code,destination_url'),s.rpc('admin_member_count'),s.rpc('admin_offer_click_summary')]);
  if(a.error||b.error){setError(a.error?.message||b.error?.message||'Failed to load');return}
  setOffers(a.data||[]);setDestinations(b.data||[]);if(!c.error)setMembers(c.data);
  if(d.error)setAnalyticsError('Click analytics unavailable: '+d.error.message);else{setClicks(d.data||[]);setAnalyticsError('')}
 }
 useEffect(()=>{(async()=>{
  const s=db();const {data:{user}}=await s.auth.getUser();if(!user){location.replace('/login');return}
  const {data, error}=await s.from('admin_users').select('user_id').eq('user_id',user.id).maybeSingle();
  if(error||!data){setLoading(false);return}
  setAuthorized(true);await refresh();setLoading(false);
 })()},[]);
 function choose(o?:Offer){setError('');setNotice('');setSelected(o?.id||'');setTitle(o?.title||'');setDescription(o?.description||'');setCategory(o?.category||'Paid Surveys');setStatus(o?.status||'draft');setAllowed(o?.countries_allowed||['ZW']);const next:Record<string,string>={};destinations.filter(d=>d.opportunity_id===o?.id).forEach(d=>next[d.country_code]=d.destination_url);setLinks(next)}
 async function deleteDraft(){
  const offer=offers.find(o=>o.id===selected);
  if(!offer||offer.status!=='draft'){setError('Only draft opportunities can be deleted.');return}
  if(!window.confirm('Permanently delete draft "'+offer.title+'"? This cannot be undone.'))return;
  setSaving(true);setError('');setNotice('');
  const s=db();const res=await s.from('opportunities').delete().eq('id',offer.id).eq('status','draft').select('id');
  if(res.error){setError(res.error.message);setSaving(false);return}
  if(!res.data?.length){setError('Draft was not deleted. Refresh and try again.');setSaving(false);return}
  choose();await refresh();setSaving(false);setNotice('Draft deleted.');
 }
 async function save(e:React.FormEvent){e.preventDefault();setError('');setNotice('');const s=db();
  if(!title.trim()||!category.trim()||allowed.length===0){setError('Enter title, category and at least one country.');return}
  for(const country of allowed){const url=(links[country]||'').trim();if(status==='published'&&!url){setError('Published offers require a destination for '+country);return}if(url){let parsed:URL;try{parsed=new URL(url)}catch{setError('Invalid URL for '+country);return}if(parsed.protocol!=='https:'||!['afflat3e1.com','afflat3e3.com'].includes(parsed.hostname)){setError('Destination domain not permitted for '+country);return}}}
  setSaving(true);
  const payload={title:title.trim(),description,category:category.trim(),countries_allowed:allowed,status:selected&&status==='published'?'draft':status};
  const res=selected?await s.from('opportunities').update(payload).eq('id',selected).select('id').single():await s.from('opportunities').insert(payload).select('id').single();
  if(res.error||!res.data){setError(res.error?.message||'Save failed');setSaving(false);return}
  const id=res.data.id;
  for(const country of countries){
   const url=(links[country]||'').trim();
   if(!allowed.includes(country)||!url){if(selected){const del=await s.from('opportunity_destinations').delete().eq('opportunity_id',id).eq('country_code',country);if(del.error){setError(del.error.message);setSaving(false);return}}continue}
   let parsed:URL;try{parsed=new URL(url)}catch{setError('Invalid URL for '+country);return}
   if(parsed.protocol!=='https:'||!['afflat3e1.com','afflat3e3.com'].includes(parsed.hostname)){setError('Destination domain not permitted for '+country);return}
   const up=await s.from('opportunity_destinations').upsert({opportunity_id:id,country_code:country,destination_url:url},{onConflict:'opportunity_id,country_code'});
   if(up.error){setError(up.error.message);setSaving(false);return}
  }
  if(status==='published'&&selected){const publish=await s.from('opportunities').update({status:'published'}).eq('id',id);if(publish.error){setError(publish.error.message);setSaving(false);return}}
  await refresh();setSelected(id);setSaving(false);setNotice('Saved. Changes are live in the database.');
 }
 return <main className="shell"><header className="top"><Link className="brand" href="/">Side Income <span>Lab</span></Link><Link className="btn alt" href="/dashboard">Member Vault</Link></header>
 <section className="hero"><span className="tag">Administration</span><h1>Opportunity <span style={{color:'#27e5ad'}}>Control.</span></h1><p className="sub">Manage listings and destinations. All writes require administrator permissions.</p></section>
 {loading?<p>Checking permissions…</p>:!authorized?<div className="panel"><h2>Access denied</h2><p>This account is not an administrator. Access must be granted by the project owner.</p></div>:<>
 <div className="panel"><h2>Overview</h2><p>{offers.length} listings · {offers.filter(x=>x.status==='published').length} published · {members===null?'Member count unavailable':members+' registered members'}</p></div>
 <div className="panel" style={{marginTop:20}}><h2>Offer engagement</h2><p className="sub">Recorded outbound clicks are not conversions or commissions.</p><p><strong>{clicks.reduce((n,x)=>n+Number(x.clicks),0)}</strong> recorded clicks · <strong>{new Set(clicks.map(x=>x.country_code)).size}</strong> countries with activity</p>{analyticsError&&<p role="alert" className="error">{analyticsError}</p>}{clicks.length>0?<div className="admin-analytics">{clicks.map(x=><div className="admin-country" key={x.opportunity_id+":"+x.country_code}><strong>{offers.find(o=>o.id===x.opportunity_id)?.title||"Opportunity"}</strong> · {x.country_code}<p>{x.clicks} clicks · {x.unique_members} unique members</p></div>)}</div>:!analyticsError&&<p className="muted">No clicks recorded yet.</p>}<button className="btn alt" type="button" onClick={refresh}>Refresh analytics</button></div>
 <div className="panel" style={{marginTop:20}}><h2>Listings</h2><div className="actions"><button className="btn" onClick={()=>choose()}>+ New opportunity</button>{offers.map(o=><button key={o.id} className="btn alt" onClick={()=>choose(o)}>{o.title} ({o.status})</button>)}</div></div>
 <form className="panel admin-form" style={{marginTop:20}} onSubmit={save}><h2>{selected?'Edit opportunity':'New opportunity'}</h2>
 <div className="admin-fields"><label>Title<input required value={title} onChange={e=>setTitle(e.target.value)}/></label>
 <label>Description<textarea value={description} onChange={e=>setDescription(e.target.value)} rows={3}/></label>
 <label>Category<input required value={category} onChange={e=>setCategory(e.target.value)}/></label>
 <label>Status<select value={status} onChange={e=>setStatus(e.target.value)}><option value="draft">Draft</option><option value="published">Published</option><option value="archived">Archived</option></select></label>
 </div><h3>Countries and tracking links</h3>{countries.map(c=><div key={c} className="admin-country"><label><input type="checkbox" checked={allowed.includes(c)} onChange={e=>setAllowed(p=>e.target.checked?[...p,c]:p.filter(x=>x!==c))}/> {c}</label>{allowed.includes(c)&&<input style={{width:'100%'}} placeholder={'HTTPS affiliate destination for '+c} value={links[c]||''} onChange={e=>setLinks(p=>({...p,[c]:e.target.value}))}/>}</div>)}
 <p className="muted">Use approved MaxBounty raw tracking URLs. Members see branded /go/ links. Published listings without a destination cannot redirect for that country.</p>
 {error&&<p role="alert" className="error">{error}</p>}{notice&&<p role="status">{notice}</p>}
 <div className="actions"><button className="btn" type="submit" disabled={saving}>{saving?"Saving…":"Save opportunity"}</button>{selected&&offers.find(o=>o.id===selected)?.status==="draft"&&<button type="button" className="btn alt" disabled={saving} onClick={deleteDraft}>Delete draft</button>}</div></form></>}
 </main>
}
