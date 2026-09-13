import React,{useEffect,useState}from'react';
import{ArrowRight,LockKeyhole,Smartphone}from'lucide-react';
import{currentAppUser}from'../services/auth';
const digits=v=>String(v||'').replace(/\D/g,'').slice(-10);
export default function BusinessLogin(){
 const[mobile,setMobile]=useState(''),[pin,setPin]=useState(''),[busy,setBusy]=useState(false),[err,setErr]=useState('');
 useEffect(()=>{currentAppUser().then(u=>{if(u?.active)location.replace('/v2.html')}).catch(()=>{})},[]);
 const submit=async e=>{e.preventDefault();setErr('');if(digits(mobile).length!==10)return setErr('ENTER A VALID 10-DIGIT MOBILE NUMBER.');if(!/^\d{4}$/.test(pin))return setErr('ENTER YOUR 4-DIGIT PIN.');setBusy(true);/* PIN verification stays server-side; never compare credentials in the client. */setBusy(false);setErr('LOGIN SERVICE IS NOT CONNECTED YET.');};
 return <main className="loginPage"><section className="loginCard">
  <header className="loginBrand"><div className="mark">T</div><div><strong>TORVO</strong><span>TOOLS PRIVATE LIMITED</span></div></header>
  <div className="loginIntro"><span className="eyebrow">SECURE BUSINESS ACCESS</span><h1>LOGIN</h1><p>ENTER YOUR REGISTERED MOBILE NUMBER AND PIN.</p></div>
  <form onSubmit={submit}>
   <label>MOBILE NUMBER<div className="loginInput"><Smartphone size={18}/><span className="country">+91</span><input autoFocus inputMode="numeric" autoComplete="tel" value={mobile} onChange={e=>setMobile(digits(e.target.value))} placeholder="10-DIGIT MOBILE NUMBER"/></div></label>
   <label>4-DIGIT PIN<div className="loginInput"><LockKeyhole size={18}/><input inputMode="numeric" type="password" autoComplete="current-password" maxLength="4" value={pin} onChange={e=>setPin(e.target.value.replace(/\D/g,'').slice(0,4))} placeholder="ENTER PIN"/></div></label>
   {err&&<div className="inlineError" role="alert">{err}</div>}
   <button className="primary loginContinue" disabled={busy}>{busy?'CHECKING…':'CONTINUE'} <ArrowRight size={17}/></button>
  </form>
  <button type="button" className="loginHelp">FORGOT PIN?</button>
  <p className="loginFoot">ONE LOGIN FOR DEALER, SALESMAN, STORE KEEPER AND AUTHORIZED TORVO STAFF.</p>
 </section></main>
}
