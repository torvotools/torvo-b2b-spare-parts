import React, { useEffect, useRef, useState } from 'react';
import {
  ArrowRight,
  BarChart3,
  Check,
  CheckCircle2,
  Clock3,
  LockKeyhole,
  RefreshCw,
  Send,
  Settings,
  ShieldCheck,
  UserRound,
  UsersRound,
  XCircle,
} from 'lucide-react';
import { currentAppUser, signOut } from '../services/auth';
import {
  beginStaffEmailOtp,
  verifyStaffEmailOtp,
  normalizeStaffUsername,
  isBusinessStaffUserId,
} from '../services/staffAuth';
import {
  roleRuntimeAllowed,
  operationalAppOnlyReason,
  webBusinessOnlyReason,
} from '../services/runtimePlatform';

const ROLE_BY_ID = {
  'OR@000': 'OWNER',
  'AD@001': 'ADMIN',
  'AC@002': 'ACCOUNTANT',
  'AC@003': 'ACCOUNTANT',
};

export default function LoginVisualPreview() {
  const otpRef = useRef(null);
  const loginRef = useRef(null);
  const [username, setUsername] = useState('');
  const [challenge, setChallenge] = useState('');
  const [otp, setOtp] = useState('');
  const [otpSent, setOtpSent] = useState(false);
  const [resendIn, setResendIn] = useState(0);
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState('');
  const [notice, setNotice] = useState('');

  useEffect(() => {
    if (!otpSent || resendIn <= 0) return undefined;
    const timer = setTimeout(() => setResendIn((value) => value - 1), 1000);
    return () => clearTimeout(timer);
  }, [otpSent, resendIn]);

  const normalized = normalizeStaffUsername(username);
  const userEntered = normalized.length > 0;
  const userValid = isBusinessStaffUserId(normalized);
  const role = userValid ? ROLE_BY_ID[normalized] : '';
  const otpReady = otp.length === 6;

  const sendOtp = async () => {
    if (!userValid || busy) return;
    setBusy(true);
    setErr('');
    setNotice('');
    try {
      const result = await beginStaffEmailOtp(normalized);
      setChallenge(result.challenge_id);
      setOtp('');
      setOtpSent(true);
      setResendIn(Number(result.resend_after_seconds) || 45);
      setNotice('OTP SENT TO THE REGISTERED TORVO SECURITY EMAIL.');
      requestAnimationFrame(() => otpRef.current?.focus());
    } catch (error) {
      setErr(error.message || 'OTP COULD NOT BE SENT.');
    } finally {
      setBusy(false);
    }
  };

  const resendOtp = async () => {
    if (!otpSent || resendIn > 0 || busy) return;
    await sendOtp();
  };

  const verify = async () => {
    if (!otpReady || !challenge || busy) return;
    setBusy(true);
    setErr('');
    setNotice('');
    try {
      const result = await verifyStaffEmailOtp(normalized, challenge, otp);
      if (!result?.staff_session_id) throw new Error('INCORRECT OTP. PLEASE TRY AGAIN.');

      const user = await currentAppUser();
      if (!user?.active) throw new Error('ACTIVE AUTHORIZED ACCOUNT REQUIRED.');
      if (!roleRuntimeAllowed(user.role)) {
        await signOut();
        throw new Error(
          ['dealer', 'salesman', 'store_keeper'].includes(user.role)
            ? operationalAppOnlyReason(user.role)
            : webBusinessOnlyReason(user.role),
        );
      }
      location.replace('/v2.html');
    } catch (error) {
      setErr(error.message || 'INCORRECT OTP. PLEASE TRY AGAIN.');
    } finally {
      setBusy(false);
    }
  };

  const changeUser = (value) => {
    setUsername(normalizeStaffUsername(value).slice(0, 15));
    setChallenge('');
    setOtp('');
    setOtpSent(false);
    setResendIn(0);
    setErr('');
    setNotice('');
  };

  return (
    <main className="businessFinalLogin">
      <section className="businessFinalHero">
        <div className="businessFinalHeroShade" />
        <div className="businessFinalHeroContent">
          <div className="businessFinalLogo">
            <span className="businessFinalMark">T</span>
            <div><strong>TORVO</strong><small>TOOLS</small></div>
          </div>
          <p className="businessFinalPortal">TORVO TOOLS B2B PORTAL</p>
          <h1>ONE TORVO<br />PLATFORM.<br /><em>THE RIGHT<br />WORKSPACE FOR<br />EACH ROLE.</em></h1>
          <p className="businessFinalTagline">SECURE. AUTHORISED. ROLE BASED.<br />BUILT FOR POWER TOOL BUSINESS.</p>

          <div className="businessFinalBenefits">
            <div><span><UsersRound /></span><p><b>ROLE BASED</b><small>Right access for every role</small></p></div>
            <div><span><ShieldCheck /></span><p><b>SECURE ACCESS</b><small>Verified users only</small></p></div>
            <div><span><Settings /></span><p><b>BUSINESS READY</b><small>Designed for business operations</small></p></div>
            <div><span><BarChart3 /></span><p><b>GROW TOGETHER</b><small>A stronger power tool network</small></p></div>
          </div>
        </div>
      </section>

      <section className="businessFinalFormSide">
        <div className="businessFinalCard">
          <div className="businessFinalCardLogo">
            <span className="businessFinalMark">T</span>
            <div><strong>TORVO</strong><small>TOOLS</small></div>
          </div>
          <p className="businessFinalCardPortal">TORVO TOOLS B2B PORTAL</p>
          <h2>WELCOME</h2>
          <p className="businessFinalSubtitle">Secure Access to Your Workspace</p>

          <div className="businessFinalInfo">
            <LockKeyhole />
            <span>Enter your <b>User ID</b>. We will send a secure OTP to the registered TORVO security email.</span>
          </div>

          <label className="businessFinalLabel">
            USER ID
            <div className={`businessFinalInput ${userEntered ? (userValid ? 'isValid' : 'isInvalid') : ''}`}>
              <UserRound />
              <input
                autoFocus
                value={username}
                onChange={(event) => changeUser(event.target.value)}
                onKeyDown={(event) => {
                  if (event.key === 'Enter') {
                    event.preventDefault();
                    if (userValid) sendOtp();
                  }
                }}
                autoComplete="off"
                autoCorrect="off"
                autoCapitalize="characters"
                spellCheck={false}
                placeholder="ENTER YOUR USER ID"
              />
              {userEntered && (userValid
                ? <CheckCircle2 className="businessFinalGood" />
                : <XCircle className="businessFinalBad" />)}
            </div>
          </label>

          {userEntered && (
            <div className={`businessFinalStatus ${userValid ? 'ok' : 'bad'}`}>
              {userValid ? <ShieldCheck /> : <XCircle />}
              <span>{userValid ? <>VALID USER ID <i /> ROLE: <b>{role}</b></> : 'INVALID USER ID'}</span>
            </div>
          )}

          <button className="businessFinalPrimary" disabled={!userValid || busy} onClick={sendOtp}>
            <Send /> {busy && !otpSent ? 'SENDING OTP…' : 'SEND OTP'}
          </button>

          <label className="businessFinalLabel businessFinalOtpLabel">
            ENTER OTP
            <div className="businessFinalInput">
              <ShieldCheck />
              <input
                ref={otpRef}
                value={otp}
                onChange={(event) => {
                  setOtp(event.target.value.replace(/\D/g, '').slice(0, 6));
                  setErr('');
                }}
                onKeyDown={(event) => {
                  if (event.key === 'Enter') {
                    event.preventDefault();
                    if (otpReady) loginRef.current?.focus();
                  }
                }}
                disabled={!otpSent}
                inputMode="numeric"
                autoComplete="one-time-code"
                maxLength={6}
                placeholder={otpSent ? 'ENTER 6-DIGIT OTP' : 'SEND OTP FIRST'}
              />
              {otpSent && otpReady && <CheckCircle2 className="businessFinalGood" />}
            </div>
          </label>

          {notice && !err && <div className="businessFinalOtpNotice"><CheckCircle2 />{notice}</div>}
          {err && <div className="businessFinalError" role="alert"><XCircle />{err}</div>}

          <div className="businessFinalResend">
            <span><Clock3 />{otpSent && resendIn > 0 ? <>Resend OTP in <b>00:{String(resendIn).padStart(2, '0')}</b></> : 'OTP VALID FOR 10 MINUTES'}</span>
            <button type="button" disabled={!otpSent || resendIn > 0 || busy} onClick={resendOtp}>
              <RefreshCw /> RESEND OTP
            </button>
          </div>

          <button
            ref={loginRef}
            className="businessFinalPrimary businessFinalLoginButton"
            disabled={!otpSent || !otpReady || busy}
            onClick={verify}
          >
            <Check /> {busy && otpSent ? 'VERIFYING…' : 'LOGIN TO YOUR WORKSPACE'} <ArrowRight />
          </button>
        </div>
      </section>
    </main>
  );
}
