import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../config/env_config.dart';

class EmailService {
  static Future<void> _send({
    required String to,
    required String subject,
    required String htmlBody,
  }) async {
    final server = gmail(
      EnvConfig.emailAddress,
      EnvConfig.emailAppPassword,
    );

    final message = Message()
      ..from = Address(EnvConfig.emailAddress, 'FreshBasket')
      ..recipients.add(to)
      ..subject = subject
      ..html = htmlBody;

    await send(message, server);
  }

  static Future<void> sendVerificationEmail({
    required String to,
    required String name,
    required String link,
  }) async {
    await _send(
      to: to,
      subject: 'Verify your FreshBasket account',
      htmlBody: _verificationTemplate(name: name, link: link),
    );
  }

  static Future<void> sendPasswordReset({
    required String to,
    required String name,
    required String link,
  }) async {
    await _send(
      to: to,
      subject: 'Reset your FreshBasket password',
      htmlBody: _passwordResetTemplate(name: name, link: link),
    );
  }

  static Future<void> sendOrderConfirmation({
    required String to,
    required String name,
    required String orderId,
    required double total,
  }) async {
    await _send(
      to: to,
      subject: 'Order Confirmed — FreshBasket',
      htmlBody: _orderConfirmationTemplate(
        name: name,
        orderId: orderId,
        total: total,
      ),
    );
  }

  static Future<void> sendSellerApproval({
    required String to,
    required String name,
    required bool approved,
    String? reason,
  }) async {
    await _send(
      to: to,
      subject: approved
          ? 'Your FreshBasket seller account is approved!'
          : 'FreshBasket seller application update',
      htmlBody: _sellerApprovalTemplate(
        name: name,
        approved: approved,
        reason: reason,
      ),
    );
  }

  static Future<void> sendDriverAccountCreated({
    required String to,
    required String name,
    required String tempPassword,
  }) async {
    await _send(
      to: to,
      subject: 'Your FreshBasket driver account is ready',
      htmlBody: _driverAccountTemplate(
        name: name,
        email: to,
        tempPassword: tempPassword,
      ),
    );
  }

  static Future<void> sendUserAccountCreated({
    required String to,
    required String name,
    required String role,
    required String tempPassword,
  }) async {
    await _send(
      to: to,
      subject: 'Welcome to FreshBasket — Your account is ready',
      htmlBody: _userAccountTemplate(
        name: name,
        email: to,
        role: role,
        tempPassword: tempPassword,
      ),
    );
  }

  static Future<void> sendDriverAssignedNotification({
    required String to,
    required String customerName,
    required String driverName,
    required String driverPhone,
    required String orderId,
  }) async {
    await _send(
      to: to,
      subject: 'Your driver is on the way — FreshBasket',
      htmlBody: _driverAssignedTemplate(
        customerName: customerName,
        driverName: driverName,
        driverPhone: driverPhone,
        orderId: orderId,
      ),
    );
  }

  static Future<void> sendOrderDelivered({
    required String to,
    required String name,
    required String orderId,
    required double total,
  }) async {
    await _send(
      to: to,
      subject: 'Order Delivered — FreshBasket',
      htmlBody: _orderDeliveredTemplate(
        name: name,
        orderId: orderId,
        total: total,
      ),
    );
  }

  static Future<void> sendOrderCancelled({
    required String to,
    required String name,
    required String orderId,
    String? reason,
  }) async {
    await _send(
      to: to,
      subject: 'Order Cancelled — FreshBasket',
      htmlBody: _orderCancelledTemplate(
        name: name,
        orderId: orderId,
        reason: reason,
      ),
    );
  }

  static Future<void> sendSellerNewOrder({
    required String to,
    required String sellerName,
    required String customerName,
    required String orderId,
    required double total,
    required int itemCount,
  }) async {
    await _send(
      to: to,
      subject: 'New Order Received — FreshBasket',
      htmlBody: _sellerNewOrderTemplate(
        sellerName: sellerName,
        customerName: customerName,
        orderId: orderId,
        total: total,
        itemCount: itemCount,
      ),
    );
  }

  // --- HTML Templates ---

  static String _base({required String content}) => '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: 'Segoe UI', Arial, sans-serif; background: #f8faf8; margin: 0; padding: 0; }
    .wrapper { max-width: 600px; margin: 40px auto; background: #fff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 24px rgba(46,158,46,0.08); }
    .header { background: linear-gradient(135deg, #2E9E2E 0%, #1A5C1A 100%); padding: 32px 40px; text-align: center; }
    .header h1 { color: #fff; margin: 0; font-size: 28px; font-weight: 700; letter-spacing: -0.5px; }
    .header p { color: rgba(255,255,255,0.85); margin: 8px 0 0; font-size: 14px; }
    .body { padding: 40px; }
    .body p { color: #1A2A1A; line-height: 1.7; font-size: 15px; }
    .btn { display: inline-block; background: #2E9E2E; color: #fff !important; text-decoration: none; padding: 14px 32px; border-radius: 10px; font-weight: 600; font-size: 16px; margin: 24px 0; }
    .footer { background: #f1f8e9; padding: 24px 40px; text-align: center; }
    .footer p { color: #5A7A5A; font-size: 13px; margin: 0; }
    .accent { color: #E8651A; font-weight: 600; }
    .divider { border: none; border-top: 1px solid #e8f0e8; margin: 24px 0; }
  </style>
</head>
<body>
  <div class="wrapper">
    <div class="header">
      <h1>FreshBasket</h1>
      <p>Freshness Delivered.</p>
    </div>
    <div class="body">$content</div>
    <div class="footer">
      <p>FreshBasket &bull; freshbasketrw@gmail.com</p>
      <p style="margin-top:8px">You received this because you have an account with FreshBasket.</p>
    </div>
  </div>
</body>
</html>
''';

  static String _verificationTemplate(
      {required String name, required String link}) =>
      _base(content: '''
<p>Hi <strong>$name</strong>,</p>
<p>Thank you for joining FreshBasket! Please verify your email address to activate your account.</p>
<p style="text-align:center"><a class="btn" href="$link">Verify Email Address</a></p>
<hr class="divider">
<p style="color:#5A7A5A;font-size:13px">This link expires in 24 hours. If you did not create a FreshBasket account, you can safely ignore this email.</p>
''');

  static String _passwordResetTemplate(
      {required String name, required String link}) =>
      _base(content: '''
<p>Hi <strong>$name</strong>,</p>
<p>We received a request to reset your FreshBasket password. Click below to set a new password.</p>
<p style="text-align:center"><a class="btn" href="$link">Reset Password</a></p>
<hr class="divider">
<p style="color:#5A7A5A;font-size:13px">This link expires in 1 hour. If you did not request a password reset, please ignore this email.</p>
''');

  static String _orderConfirmationTemplate({
    required String name,
    required String orderId,
    required double total,
  }) =>
      _base(content: '''
<p>Hi <strong>$name</strong>,</p>
<p>Your FreshBasket order has been confirmed! Here are your order details:</p>
<table style="width:100%;border-collapse:collapse;margin:16px 0">
  <tr><td style="padding:8px 0;color:#5A7A5A">Order ID</td><td style="padding:8px 0;font-weight:600">#${orderId.substring(0, 8).toUpperCase()}</td></tr>
  <tr><td style="padding:8px 0;color:#5A7A5A">Total</td><td style="padding:8px 0;font-weight:600" class="accent">RWF ${total.toStringAsFixed(0)}</td></tr>
  <tr><td style="padding:8px 0;color:#5A7A5A">Payment</td><td style="padding:8px 0">Cash on Delivery</td></tr>
</table>
<p>You can track your order in real-time using the FreshBasket app.</p>
<p style="color:#5A7A5A;font-size:13px">Thank you for choosing FreshBasket!</p>
''');

  static String _sellerApprovalTemplate({
    required String name,
    required bool approved,
    String? reason,
  }) =>
      _base(content: approved
          ? '''
<p>Hi <strong>$name</strong>,</p>
<p>Great news! Your FreshBasket seller account has been <strong style="color:#2E9E2E">approved</strong>!</p>
<p>You can now log in to your seller dashboard and start adding your products.</p>
<p style="color:#5A7A5A;font-size:13px">Welcome to the FreshBasket family!</p>
'''
          : '''
<p>Hi <strong>$name</strong>,</p>
<p>We have reviewed your FreshBasket seller application and unfortunately could not approve it at this time.</p>
${reason != null ? '<p><strong>Reason:</strong> $reason</p>' : ''}
<p>Please contact us at <a href="mailto:freshbasketrw@gmail.com">freshbasketrw@gmail.com</a> for more information or to reapply.</p>
''');

  static String _driverAccountTemplate({
    required String name,
    required String email,
    required String tempPassword,
  }) =>
      _base(content: '''
<p>Hi <strong>$name</strong>,</p>
<p>Your FreshBasket driver account has been created. Use the credentials below to log in:</p>
<table style="width:100%;border-collapse:collapse;margin:16px 0">
  <tr><td style="padding:8px 0;color:#5A7A5A">Email</td><td style="padding:8px 0;font-weight:600">$email</td></tr>
  <tr><td style="padding:8px 0;color:#5A7A5A">Temp Password</td><td style="padding:8px 0;font-weight:600" class="accent">$tempPassword</td></tr>
</table>
<p>Please change your password after your first login.</p>
<p style="color:#5A7A5A;font-size:13px">Welcome to the FreshBasket delivery team!</p>
''');

  static String _userAccountTemplate({
    required String name,
    required String email,
    required String role,
    required String tempPassword,
  }) =>
      _base(content: '''
<p>Hi <strong>$name</strong>,</p>
<p>Your FreshBasket ${role[0].toUpperCase()}${role.substring(1)} account has been created by an administrator. Use the credentials below to log in:</p>
<table style="width:100%;border-collapse:collapse;margin:16px 0">
  <tr><td style="padding:8px 0;color:#5A7A5A">Email</td><td style="padding:8px 0;font-weight:600">$email</td></tr>
  <tr><td style="padding:8px 0;color:#5A7A5A">Temp Password</td><td style="padding:8px 0;font-weight:600" class="accent">$tempPassword</td></tr>
  <tr><td style="padding:8px 0;color:#5A7A5A">Account Type</td><td style="padding:8px 0;font-weight:600">${role[0].toUpperCase()}${role.substring(1)}</td></tr>
</table>
<p>Please change your password after your first login. Open the FreshBasket app and sign in with the credentials above.</p>
<p style="color:#5A7A5A;font-size:13px">Welcome to FreshBasket!</p>
''');

  static String _driverAssignedTemplate({
    required String customerName,
    required String driverName,
    required String driverPhone,
    required String orderId,
  }) =>
      _base(content: '''
<p>Hi <strong>$customerName</strong>,</p>
<p>Great news! A driver has been assigned to deliver your order.</p>
<table style="width:100%;border-collapse:collapse;margin:16px 0">
  <tr><td style="padding:8px 0;color:#5A7A5A">Order ID</td><td style="padding:8px 0;font-weight:600">#${orderId.length >= 8 ? orderId.substring(0, 8).toUpperCase() : orderId.toUpperCase()}</td></tr>
  <tr><td style="padding:8px 0;color:#5A7A5A">Driver</td><td style="padding:8px 0;font-weight:600">$driverName</td></tr>
  <tr><td style="padding:8px 0;color:#5A7A5A">Driver Phone</td><td style="padding:8px 0;font-weight:600">$driverPhone</td></tr>
</table>
<p>You can track your delivery in real-time using the FreshBasket app.</p>
<p style="color:#5A7A5A;font-size:13px">Thank you for choosing FreshBasket!</p>
''');

  static String _orderDeliveredTemplate({
    required String name,
    required String orderId,
    required double total,
  }) =>
      _base(content: '''
<p>Hi <strong>$name</strong>,</p>
<p>Your FreshBasket order has been <strong style="color:#2E9E2E">delivered</strong>. We hope you enjoy your fresh produce!</p>
<table style="width:100%;border-collapse:collapse;margin:16px 0">
  <tr><td style="padding:8px 0;color:#5A7A5A">Order ID</td><td style="padding:8px 0;font-weight:600">#${orderId.length >= 8 ? orderId.substring(0, 8).toUpperCase() : orderId.toUpperCase()}</td></tr>
  <tr><td style="padding:8px 0;color:#5A7A5A">Total Paid</td><td style="padding:8px 0;font-weight:600" class="accent">RWF ${total.toStringAsFixed(0)}</td></tr>
  <tr><td style="padding:8px 0;color:#5A7A5A">Payment</td><td style="padding:8px 0">Cash on Delivery</td></tr>
</table>
<p>If you enjoyed your order, please take a moment to leave a review in the app. Your feedback helps our sellers grow!</p>
<p style="color:#5A7A5A;font-size:13px">Thank you for choosing FreshBasket — we'll see you next time!</p>
''');

  static String _orderCancelledTemplate({
    required String name,
    required String orderId,
    String? reason,
  }) =>
      _base(content: '''
<p>Hi <strong>$name</strong>,</p>
<p>Your FreshBasket order has been <strong style="color:#E53935">cancelled</strong>.</p>
<table style="width:100%;border-collapse:collapse;margin:16px 0">
  <tr><td style="padding:8px 0;color:#5A7A5A">Order ID</td><td style="padding:8px 0;font-weight:600">#${orderId.length >= 8 ? orderId.substring(0, 8).toUpperCase() : orderId.toUpperCase()}</td></tr>
  ${reason != null ? '<tr><td style="padding:8px 0;color:#5A7A5A">Reason</td><td style="padding:8px 0">$reason</td></tr>' : ''}
</table>
<p>No payment was collected since FreshBasket uses Cash on Delivery. We're sorry for the inconvenience.</p>
<p>If you have questions, please contact us at <a href="mailto:freshbasketrw@gmail.com">freshbasketrw@gmail.com</a>.</p>
<p style="color:#5A7A5A;font-size:13px">We hope to serve you again soon!</p>
''');

  static String _sellerNewOrderTemplate({
    required String sellerName,
    required String customerName,
    required String orderId,
    required double total,
    required int itemCount,
  }) =>
      _base(content: '''
<p>Hi <strong>$sellerName</strong>,</p>
<p>You have received a new order on FreshBasket!</p>
<table style="width:100%;border-collapse:collapse;margin:16px 0">
  <tr><td style="padding:8px 0;color:#5A7A5A">Order ID</td><td style="padding:8px 0;font-weight:600">#${orderId.length >= 8 ? orderId.substring(0, 8).toUpperCase() : orderId.toUpperCase()}</td></tr>
  <tr><td style="padding:8px 0;color:#5A7A5A">Customer</td><td style="padding:8px 0;font-weight:600">$customerName</td></tr>
  <tr><td style="padding:8px 0;color:#5A7A5A">Items</td><td style="padding:8px 0;font-weight:600">$itemCount item${itemCount != 1 ? 's' : ''}</td></tr>
  <tr><td style="padding:8px 0;color:#5A7A5A">Order Total</td><td style="padding:8px 0;font-weight:600" class="accent">RWF ${total.toStringAsFixed(0)}</td></tr>
</table>
<p>Please open the FreshBasket seller app to confirm and prepare this order.</p>
<p style="color:#5A7A5A;font-size:13px">Thank you for being a FreshBasket seller!</p>
''');
}
