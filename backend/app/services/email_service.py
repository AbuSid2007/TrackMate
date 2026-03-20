import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from app.core.config import settings


class EmailService:

    def _send(self, to: str, subject: str, html: str) -> None:
        print(f"[Email] _send called. enabled={settings.email_enabled} to={to}")
        if not settings.email_enabled:
            print(f"[Email disabled] To: {to} | Subject: {subject}")
            return

        print(f"[Email] Connecting to {settings.SMTP_HOST}:{settings.SMTP_PORT} as {settings.SMTP_USER}")
        msg = MIMEMultipart("alternative")
        msg["Subject"] = subject
        msg["From"] = f"{settings.EMAIL_FROM_NAME} <{settings.EMAIL_FROM}>"
        msg["To"] = to
        msg.attach(MIMEText(html, "html"))

        try:
            with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT) as server:
                server.ehlo()
                server.starttls()
                server.login(settings.SMTP_USER, settings.SMTP_PASSWORD)
                server.sendmail(settings.EMAIL_FROM, to, msg.as_string())
                print(f"[Email] Sent successfully to {to}")
        except Exception as e:
            print(f"[Email] SMTP error: {type(e).__name__}: {e}")
            raise

    def send_verification_email(self, to: str, full_name: str, otp: str) -> None:
        html = f"""
        <p>Hi {full_name},</p>
        <p>Your TrackMate verification code is:</p>
        <h2 style="letter-spacing: 8px; font-size: 32px; color: #2563EB;">{otp}</h2>
        <p>This code expires in 10 minutes.</p>
        <p>— TrackMate</p>
        """
        self._send(to, "Your TrackMate verification code", html)
        
    def send_trainer_approved_email(self, to: str, full_name: str) -> None:
        html = f"""
        <p>Hi {full_name},</p>
        <p>Your trainer application has been <strong>approved</strong>.</p>
        <p>You can now log in as a trainer and start managing trainees.</p>
        <p>— TrackMate</p>
        """
        self._send(to, "Your trainer application was approved", html)

    def send_trainer_rejected_email(self, to: str, full_name: str) -> None:
        html = f"""
        <p>Hi {full_name},</p>
        <p>Unfortunately your trainer application was not approved at this time.</p>
        <p>Contact support if you believe this is a mistake.</p>
        <p>— TrackMate</p>
        """
        self._send(to, "Your trainer application was not approved", html)


email_service = EmailService()