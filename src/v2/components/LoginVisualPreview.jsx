import React, { useEffect, useRef, useState } from 'react';
import {
  ShieldCheck,
  MessageCircle,
  Mail,
  ArrowRight,
  UserRound,
  Sparkles,
  LockKeyhole,
  CheckCircle2,
  XCircle,
  Monitor,
  Smartphone,
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

export default function LoginVisualPreview() {
  const userIdRef = useRef(null);
  const continueRef = useRef(null);
  const verifyRef = useRef(null);

  const [email, setEmail] = useState('');
  const [username, setUsername] = useState('');
  const [otpOpen, setOtpOpen] = useState(false);
  const [otp, setOtp] = useState('');
  const [resendIn, setResendIn] = useState(45);
  const [challenge, setChallenge] = useState('');
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState('');

  useEffect(() => {
    if (!otpOpen || resendIn <= 0) return undefined;
    const timer = setTimeout(() => setResendIn((value) => value - 1), 1000);
    return () => clearTimeout(timer);
  }, [otpOpen, resendIn]);

  const authorizedEmail = 'torvotools@gmail.com';
  const emailEntered = email.trim().length > 0;
  const emailReady = email.trim().toLowerCase() === authorizedEmail;
  const userEntered = username.trim().length > 0;
  const userReady = isBusinessStaffUserId(username);
  const canContinue = emailReady && userReady;

  const begin = async () => {
    if (!canContinue || busy) return;
    setErr('');
    setBusy(true);
    try {
      const normalizedUsername = normalizeStaffUsername(username);
      const result = await beginStaffEmailOtp(email, normalizedUsername);
      setUsername(normalizedUsername);
      setChallenge(result.challenge_id);
      setOtp('');
      setResendIn(45);
      setOtpOpen(true);
    } catch (error) {
      setErr(error.message || 'OTP COULD NOT BE SENT.');
    } finally {
      setBusy(false);
    }
  };

  const resend = async () => {
    if (busy || resendIn > 0) return;
    setBusy(true);
    setErr('');
    try {
      const result = await beginStaffEmailOtp(email, username);
      setChallenge(result.challenge_id);
      setOtp('');
      setResendIn(45);
    } catch (error) {
      setErr(error.message || 'OTP COULD NOT BE SENT.');
    } finally {
      setBusy(false);
    }
  };

  const verify = async () => {
    if (otp.length !== 6 || busy) return;
    setErr('');
    setBusy(true);
    try {
      const result = await verifyStaffEmailOtp(username, challenge, otp);
      if (!result?.ok) throw new Error(result?.message || 'VERIFICATION FAILED.');

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
      setErr(error.message || 'VERIFICATION FAILED.');
    } finally {
      setBusy(false);
    }
  };

  return (
    <main className="loginPreview loginV2">
      <section className="loginBrand">
        <div className="loginBrandInner">
          <div className="loginLogo">
            <div className="mark loginMark">T</div>
            <strong>TORVO</strong>
          </div>
          <span className="heroPill"><Sparkles size={13} /> TORVO TOOLS B2B</span>
          <h1>ONE TORVO PLATFORM.<br /><em>THE RIGHT WORKSPACE FOR EACH ROLE.</em></h1>
          <p>APPROVED DEALERS AND OPERATIONAL STAFF USE THE TORVO APP. OWNER, ADMIN AND ACCOUNTANT USE THE SECURE DESKTOP / LAPTOP WORKSPACE.</p>
          <div className="loginFeatureRow">
            <span><CheckCircle2 size={16} />ROLE BASED</span>
            <span><CheckCircle2 size={16} />SERVER AUTHORIZED</span>
            <span><CheckCircle2 size={16} />SECURE WORKFLOW</span>
          </div>
        </div>
      </section>

      <section className="loginCardWrap">
        <div className="loginCard">
          <div className="loginCardHead">
            <div className="mark">T</div>
            <div>
              <strong>WELCOME TO TORVO</strong>
              <span>AUTHORIZED BUSINESS ACCESS</span>
            </div>
          </div>

          <div className="loginSecureBadge"><LockKeyhole size={16} /> SECURE SIGN IN</div>
          <h2>ACCESS YOUR WORKSPACE</h2>
          <p className="loginIntro">ENTER THE AUTHORIZED SECURITY EMAIL AND YOUR USER ID. YOUR USER ID IDENTIFIES THE ADMIN OR ACCOUNTANT ROLE. A 6-DIGIT EMAIL OTP COMPLETES SIGN IN.</p>

          <label>
            EMAIL ID
            <div className="loginInput">
              <Mail size={18} />
              <input
                name="torvo-security-email"
                value={email}
                onChange={(event) => setEmail(event.target.value)}
                onKeyDown={(event) => {
                  if (event.key === 'Enter') {
                    event.preventDefault();
                    userIdRef.current?.focus();
                  }
                }}
                autoComplete="off"
                autoCorrect="off"
                autoCapitalize="none"
                spellCheck={false}
                inputMode="email"
                placeholder="ENTER AUTHORIZED EMAIL ID"
              />
              {emailEntered && (emailReady
                ? <CheckCircle2 className="loginFieldVerified" size={19} />
                : <XCircle className="loginFieldInvalid" size={19} />)}
            </div>
          </label>

          <label>
            USER ID
            <div className="loginInput">
              <UserRound size={18} />
              <input
                ref={userIdRef}
                name="torvo-user-id"
                value={username}
                onChange={(event) => setUsername(event.target.value.toUpperCase())}
                onKeyDown={(event) => {
                  if (event.key === 'Enter') {
                    event.preventDefault();
                    if (canContinue) continueRef.current?.focus();
                  }
                }}
                autoComplete="off"
                autoCorrect="off"
                autoCapitalize="characters"
                spellCheck={false}
                placeholder="ENTER AUTHORIZED USER ID"
              />
              {userEntered && (userReady
                ? <CheckCircle2 className="loginFieldVerified" size={19} />
                : <XCircle className="loginFieldInvalid" size={19} />)}
            </div>
          </label>

          <button
            ref={continueRef}
            className="primary loginButton loginButtonReady"
            disabled={!canContinue}
            onClick={begin}
          >
            {busy ? 'SENDING OTP…' : 'VERIFY OTP EMAIL'} <ArrowRight size={17} />
          </button>

          {otpOpen && (
            <div className="loginOtpOverlay" role="dialog" aria-modal="true">
              <div className="loginOtpPopup">
                <button
                  type="button"
                  className="loginOtpClose"
                  aria-label="Close email verification"
                  onClick={() => {
                    setOtpOpen(false);
                    setOtp('');
                    setChallenge('');
                    setErr('');
                  }}
                >
                  <span aria-hidden="true">×</span>
                </button>

                <div className="loginSecureBadge"><Mail size={16} /> EMAIL VERIFICATION</div>
                <h3>USER ID: {username || '—'}</h3>
                <p>6-DIGIT OTP SENT TO THE AUTHORIZED SECURITY EMAIL.</p>

                <label>
                  EMAIL ID
                  <div className="loginInput loginOtpReadonly">
                    <Mail size={18} />
                    <input value={email} readOnly tabIndex={-1} />
                    <CheckCircle2 className="loginFieldVerified" size={19} />
                  </div>
                </label>

                <label>
                  USER ID
                  <div className="loginInput loginOtpReadonly">
                    <UserRound size={18} />
                    <input value={username} readOnly tabIndex={-1} />
                    <CheckCircle2 className="loginFieldVerified" size={19} />
                  </div>
                </label>

                <label>
                  EMAIL OTP
                  <div className="loginInput">
                    <LockKeyhole size={18} />
                    <input
                      autoFocus
                      autoComplete="one-time-code"
                      inputMode="numeric"
                      maxLength={6}
                      value={otp}
                      onChange={(event) => setOtp(event.target.value.replace(/\D/g, '').slice(0, 6))}
                      onKeyDown={(event) => {
                        if (event.key === 'Enter') {
                          event.preventDefault();
                          if (otp.length === 6) verifyRef.current?.focus();
                        }
                      }}
                      placeholder="ENTER 6-DIGIT OTP"
                    />
                    {otp.length === 6 && <XCircle className="loginFieldInvalid" size={19} />}
                  </div>
                </label>

                <div className="loginOtpMeta">
                  <small>OTP VALID FOR 10 MINUTES · SINGLE USE</small>
                  <button
                    type="button"
                    className="loginResend"
                    disabled={resendIn > 0}
                    onClick={resend}
                  >
                    {resendIn > 0
                      ? <><span>RESEND OTP</span><b>00:{String(resendIn).padStart(2, '0')}</b></>
                      : <><span>RESEND OTP</span><b>READY</b></>}
                  </button>
                </div>

                {err && <div className="inlineError" role="alert">{err}</div>}

                <button
                  ref={verifyRef}
                  className="primary loginButton loginButtonReady"
                  disabled={busy || otp.length !== 6}
                  onClick={verify}
                >
                  {busy ? 'VERIFYING…' : 'VERIFY & LOGIN'} <ArrowRight size={17} />
                </button>
              </div>
            </div>
          )}

          {!otpOpen && err && <div className="inlineError" role="alert">{err}</div>}

          <div className="loginDivider"><span>ROLE DESTINATION</span></div>
          <div className="loginTrustCards">
            <div><Smartphone size={18} /><span><b>DEALER / SALESMAN / STORE KEEPER</b><small>TORVO APP AFTER AUTHORIZATION</small></span></div>
            <div><Monitor size={18} /><span><b>OWNER / ADMIN / ACCOUNTANT</b><small>SECURE DESKTOP / LAPTOP</small></span></div>
            <div><ShieldCheck size={18} /><span><b>BLOCKED / INACTIVE</b><small>NO PRIVATE BUSINESS ACCESS</small></span></div>
            <div><MessageCircle size={18} /><span><b>DEALER WHATSAPP RECOVERY</b><small>PIN RECOVERY ON VERIFIED MOBILE</small></span></div>
          </div>
          <p className="loginPreviewNote">DEVELOPMENT VISUAL PREVIEW · EMAIL OTP UI PREVIEW</p>
        </div>
      </section>
    </main>
  );
}
