import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/app_export.dart';
import '../../widgets/scrolling_quote_widget.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/backend_error_handler.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _showRetryButton = false;
  bool _showPasswordReset = false;
  
  // Enhanced loading states for different operations
  bool _isAuthenticating = false;
  bool _isGuestLoading = false;
  bool _isPasswordResetLoading = false;
  AuthErrorType? _errorType;
  int _retryAttempts = 0;
  static const int _maxRetryAttempts = 3;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667EEA),
              Color(0xFF764BA2),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLogo(),
                      SizedBox(height: 48),
                      _buildAuthCard(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: SvgPicture.asset(
              'assets/images/img_app_logo.svg',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
              placeholderBuilder: (context) => Image.asset(
                'assets/images/reminder app icon.png',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        SizedBox(height: 24),
        Text(
          'Good Deeds Reminder',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        ScrollingQuoteWidget(
          quotes: [
            "Whoever has done an atom's weight of good will see it. 99:7",
            "And remind, for the reminder benefits the believers. 51:55",
          ],
          textStyle: TextStyle(
            fontSize: 18,
            color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildAuthCard() {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: Offset(0, 15),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAuthToggle(),
              SizedBox(height: 32),
              if (_errorMessage != null) ...[
                _buildErrorDisplay(),
                SizedBox(height: 20),
              ],
              if (!_isLogin) ...[
                _buildNameField(),
                SizedBox(height: 20),
              ],
              _buildEmailField(),
              SizedBox(height: 20),
              _buildPasswordField(),
              if (_isLogin && !_showPasswordReset) ...[
                SizedBox(height: 12),
                _buildForgotPasswordLink(),
              ],
              if (_showPasswordReset) ...[
                SizedBox(height: 20),
                _buildPasswordResetSection(),
              ],
              SizedBox(height: 32),
              _buildAuthButton(),
              if (_showRetryButton) ...[
                SizedBox(height: 12),
                _buildRetryButton(),
              ],
              if (!_showPasswordReset) ...[
                SizedBox(height: 20),
                _buildSwitchAuthMode(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthToggle() {
    return Column(
      children: [
        // Mode toggle buttons
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: (_isLoading || _isAuthenticating || _isGuestLoading || _isPasswordResetLoading) ? null : () => setState(() {
                  _isLogin = true;
                  _showPasswordReset = false;
                  _errorMessage = null;
                  _errorType = null;
                  _showRetryButton = false;
                  _retryAttempts = 0;
                }),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _isLogin ? Color(0xFF667EEA) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _isLogin ? Colors.white : ((_isLoading || _isAuthenticating || _isGuestLoading || _isPasswordResetLoading) ? Colors.grey[400] : Colors.grey[600]),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: (_isLoading || _isAuthenticating || _isGuestLoading || _isPasswordResetLoading) ? null : () => setState(() {
                  _isLogin = false;
                  _showPasswordReset = false;
                  _errorMessage = null;
                  _errorType = null;
                  _showRetryButton = false;
                  _retryAttempts = 0;
                }),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: !_isLogin ? Color(0xFF667EEA) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Sign Up',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: !_isLogin ? Colors.white : ((_isLoading || _isAuthenticating || _isGuestLoading || _isPasswordResetLoading) ? Colors.grey[400] : Colors.grey[600]),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        // Guest mode button
        GestureDetector(
          onTap: (_isLoading || _isAuthenticating || _isGuestLoading || _isPasswordResetLoading) ? null : _handleGuestMode,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: (_isLoading || _isAuthenticating || _isGuestLoading || _isPasswordResetLoading) ? Colors.grey[200] : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: _isGuestLoading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Loading...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  )
                : Text(
                    'Continue as Guest',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: (_isLoading || _isAuthenticating || _isPasswordResetLoading) ? Colors.grey[400] : Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      style: TextStyle(fontSize: 18, color: Colors.grey[800]),
      decoration: InputDecoration(
        labelText: 'Full Name',
        labelStyle: TextStyle(fontSize: 16, color: Colors.grey[600]),
        prefixIcon: Icon(Icons.person_outline, color: Color(0xFF667EEA)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF667EEA), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (value) {
        if (!_isLogin && (value == null || value.trim().isEmpty)) {
          return 'Please enter your full name';
        }
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: TextStyle(fontSize: 18, color: Colors.grey[800]),
      decoration: InputDecoration(
        labelText: 'Email Address',
        labelStyle: TextStyle(fontSize: 16, color: Colors.grey[600]),
        prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF667EEA)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF667EEA), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your email address';
        }
        if (!value.contains('@') || !value.contains('.')) {
          return 'Please enter a valid email address';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: TextStyle(fontSize: 18, color: Colors.grey[800]),
      decoration: InputDecoration(
        labelText: 'Password',
        labelStyle: TextStyle(fontSize: 16, color: Colors.grey[600]),
        prefixIcon: Icon(Icons.lock_outline, color: Color(0xFF667EEA)),
        suffixIcon: IconButton(
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey[600],
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF667EEA), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  Widget _buildAuthButton() {
    final isButtonLoading = _isLoading || _isAuthenticating;
    
    // Don't show auth button when in password reset mode
    if (_showPasswordReset) {
      return SizedBox.shrink();
    }
    
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: (isButtonLoading || _isGuestLoading || _isPasswordResetLoading) ? null : _handleAuth,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF667EEA),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: isButtonLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    _isLogin ? 'Signing In...' : 'Creating Account...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Text(
                _isLogin ? 'Login' : 'Create Account',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildErrorDisplay() {
    final errorInfo = _getErrorDisplayInfo();
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: errorInfo.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: errorInfo.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                errorInfo.icon,
                color: errorInfo.iconColor,
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  errorInfo.title,
                  style: TextStyle(
                    color: errorInfo.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() {
                  _errorMessage = null;
                  _errorType = null;
                  _showRetryButton = false;
                }),
                icon: Icon(
                  Icons.close,
                  color: errorInfo.iconColor,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: TextStyle(
              color: errorInfo.textColor,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          if (_retryAttempts > 0) ...[
            SizedBox(height: 8),
            Text(
              'Attempt ${_retryAttempts + 1} of $_maxRetryAttempts',
              style: TextStyle(
                color: errorInfo.textColor.withValues(alpha: 0.7),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (errorInfo.showTroubleshootingTip) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: errorInfo.tipBackgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: errorInfo.tipIconColor,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      errorInfo.troubleshootingTip,
                      style: TextStyle(
                        color: errorInfo.tipTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  ErrorDisplayInfo _getErrorDisplayInfo() {
    switch (_errorType) {
      case AuthErrorType.network:
        return ErrorDisplayInfo(
          title: 'Connection Problem',
          icon: Icons.wifi_off,
          backgroundColor: Colors.orange[50]!,
          borderColor: Colors.orange[200]!,
          iconColor: Colors.orange[600]!,
          textColor: Colors.orange[800]!,
          showTroubleshootingTip: true,
          troubleshootingTip: 'Check your internet connection and try again',
          tipBackgroundColor: Colors.orange[100]!,
          tipIconColor: Colors.orange[600]!,
          tipTextColor: Colors.orange[700]!,
        );
      case AuthErrorType.authentication:
        return ErrorDisplayInfo(
          title: 'Authentication Failed',
          icon: Icons.lock_outline,
          backgroundColor: Colors.red[50]!,
          borderColor: Colors.red[200]!,
          iconColor: Colors.red[600]!,
          textColor: Colors.red[700]!,
          showTroubleshootingTip: true,
          troubleshootingTip: 'Double-check your email and password',
          tipBackgroundColor: Colors.red[100]!,
          tipIconColor: Colors.red[600]!,
          tipTextColor: Colors.red[700]!,
        );
      case AuthErrorType.validation:
        return ErrorDisplayInfo(
          title: 'Invalid Input',
          icon: Icons.warning_amber,
          backgroundColor: Colors.amber[50]!,
          borderColor: Colors.amber[200]!,
          iconColor: Colors.amber[600]!,
          textColor: Colors.amber[800]!,
          showTroubleshootingTip: false,
          troubleshootingTip: '',
          tipBackgroundColor: Colors.amber[100]!,
          tipIconColor: Colors.amber[600]!,
          tipTextColor: Colors.amber[700]!,
        );
      case AuthErrorType.service:
        return ErrorDisplayInfo(
          title: 'Service Unavailable',
          icon: Icons.cloud_off,
          backgroundColor: Colors.purple[50]!,
          borderColor: Colors.purple[200]!,
          iconColor: Colors.purple[600]!,
          textColor: Colors.purple[700]!,
          showTroubleshootingTip: true,
          troubleshootingTip: 'Our servers are temporarily unavailable. Please try again in a few minutes.',
          tipBackgroundColor: Colors.purple[100]!,
          tipIconColor: Colors.purple[600]!,
          tipTextColor: Colors.purple[700]!,
        );
      default:
        return ErrorDisplayInfo(
          title: 'Error',
          icon: Icons.error_outline,
          backgroundColor: Colors.red[50]!,
          borderColor: Colors.red[200]!,
          iconColor: Colors.red[600]!,
          textColor: Colors.red[700]!,
          showTroubleshootingTip: false,
          troubleshootingTip: '',
          tipBackgroundColor: Colors.red[100]!,
          tipIconColor: Colors.red[600]!,
          tipTextColor: Colors.red[700]!,
        );
    }
  }

  Widget _buildRetryButton() {
    final isButtonLoading = _isLoading || _isAuthenticating;
    final canRetry = _retryAttempts < _maxRetryAttempts;
    
    return Column(
      children: [
        if (canRetry) ...[
          SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: (isButtonLoading || _isGuestLoading) ? null : _handleAuth,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Color(0xFF667EEA)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isButtonLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Retrying...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF667EEA),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.refresh,
                          color: Color(0xFF667EEA),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Try Again (${_retryAttempts + 1}/$_maxRetryAttempts)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF667EEA),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ] else ...[
          // Max retries reached - show alternative options
          Column(
            children: [
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: (isButtonLoading || _isGuestLoading) ? null : _resetAndRetry,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.orange[600]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.restart_alt,
                        color: Colors.orange[600],
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Start Over',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_errorType == AuthErrorType.network || _errorType == AuthErrorType.service) ...[
                SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: TextButton(
                    onPressed: (isButtonLoading || _isGuestLoading) ? null : _handleGuestMode,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_outline,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Continue as Guest',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  void _resetAndRetry() {
    setState(() {
      _retryAttempts = 0;
      _errorMessage = null;
      _errorType = null;
      _showRetryButton = false;
    });
    _handleAuth();
  }

  Widget _buildForgotPasswordLink() {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: (_isLoading || _isAuthenticating || _isGuestLoading || _isPasswordResetLoading) ? null : () {
          setState(() {
            _showPasswordReset = true;
            _errorMessage = null;
            _errorType = null;
            _showRetryButton = false;
          });
        },
        child: Text(
          'Forgot Password?',
          style: TextStyle(
            fontSize: 14,
            color: (_isLoading || _isAuthenticating || _isGuestLoading || _isPasswordResetLoading) 
                ? Colors.grey[400] 
                : Color(0xFF667EEA),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordResetSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
              SizedBox(width: 8),
              Text(
                'Reset Password',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[800],
                ),
              ),
              Spacer(),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showPasswordReset = false;
                    _errorMessage = null;
                    _errorType = null;
                  });
                },
                child: Icon(Icons.close, color: Colors.blue[600], size: 20),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Enter your email address and we\'ll send you a link to reset your password.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue[700],
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: (_isLoading || _isAuthenticating || _isGuestLoading || _isPasswordResetLoading) 
                  ? null 
                  : _handlePasswordReset,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isPasswordResetLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Sending...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'Send Reset Link',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchAuthMode() {
    final isDisabled = _isLoading || _isAuthenticating || _isGuestLoading || _isPasswordResetLoading;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isLogin ? "Don't have an account? " : "Already have an account? ",
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        GestureDetector(
          onTap: isDisabled ? null : () => setState(() {
            _isLogin = !_isLogin;
            _showPasswordReset = false;
            _errorMessage = null;
            _errorType = null;
            _showRetryButton = false;
            _retryAttempts = 0;
          }),
          child: Text(
            _isLogin ? 'Sign Up' : 'Login',
            style: TextStyle(
              fontSize: 16,
              color: isDisabled ? Colors.grey[400] : Color(0xFF667EEA),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }



  Future<void> _handlePasswordReset() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email address first.';
        _errorType = AuthErrorType.validation;
      });
      return;
    }

    setState(() {
      _isPasswordResetLoading = true;
      _errorMessage = null;
      _errorType = null;
    });

    try {
      final result = await AuthService.instance.resetPassword(_emailController.text.trim());
      
      if (mounted) {
        if (result.success) {
          setState(() {
            _showPasswordReset = false;
            _errorMessage = result.errorMessage; // This contains the success message
            _errorType = null;
          });
          
          // Show success dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Password Reset Sent'),
              content: Text('We\'ve sent a password reset link to ${_emailController.text.trim()}. Please check your email and follow the instructions.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('OK'),
                ),
              ],
            ),
          );
        } else {
          setState(() {
            _errorMessage = result.errorMessage;
            _errorType = result.errorType;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to send reset email. Please try again.';
          _errorType = AuthErrorType.unknown;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPasswordResetLoading = false;
        });
      }
    }
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _isAuthenticating = true;
      _errorMessage = null;
      _errorType = null;
      _showRetryButton = false;
    });

    try {
      late AuthResult result;
      
      if (_isLogin) {
        result = await AuthService.instance.login(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        result = await AuthService.instance.register(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text,
        );
      }

      if (mounted) {
        if (result.success) {
          // Clear any previous errors on success
          setState(() {
            _errorMessage = null;
            _errorType = null;
            _showRetryButton = false;
            _retryAttempts = 0;
          });
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else {
          _retryAttempts++;
          
          // Check if it's a "user already exists" error during signup
          if (!_isLogin && result.errorMessage != null && 
              (result.errorMessage!.toLowerCase().contains('already') || 
               result.errorMessage!.toLowerCase().contains('exists') ||
               result.errorMessage!.toLowerCase().contains('registered'))) {
            // Show dialog and switch to login mode
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Account Already Exists'),
                content: Text('An account with this email already exists. Please login instead.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      setState(() {
                        _isLogin = true;
                        _errorMessage = null;
                        _errorType = null;
                        _showRetryButton = false;
                        _retryAttempts = 0;
                      });
                    },
                    child: Text('Go to Login'),
                  ),
                ],
              ),
            );
            return;
          }
          
          setState(() {
            _errorMessage = result.errorMessage ?? 
                (_isLogin ? 'Login failed. Please try again.' : 'Registration failed. Please try again.');
            _errorType = result.errorType;
            _showRetryButton = result.isRetryable && _retryAttempts < _maxRetryAttempts;
          });
        }
      }
    } on BackendException catch (e) {
      if (mounted) {
        _retryAttempts++;
        setState(() {
          _errorMessage = e.userMessage;
          _errorType = _mapBackendErrorType(e.errorType);
          _showRetryButton = e.isRetryable && _retryAttempts < _maxRetryAttempts;
        });
      }
    } catch (e) {
      if (mounted) {
        _retryAttempts++;
        setState(() {
          _errorMessage = BackendErrorHandler.getUserFriendlyMessage(e);
          _errorType = AuthErrorType.unknown;
          _showRetryButton = BackendErrorHandler.isRetryable(e) && _retryAttempts < _maxRetryAttempts;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isAuthenticating = false;
        });
      }
    }
  }

  AuthErrorType _mapBackendErrorType(BackendErrorType backendType) {
    switch (backendType) {
      case BackendErrorType.authentication:
        return AuthErrorType.authentication;
      case BackendErrorType.validation:
        return AuthErrorType.validation;
      case BackendErrorType.network:
      case BackendErrorType.timeout:
        return AuthErrorType.network;
      case BackendErrorType.server:
      case BackendErrorType.database:
      case BackendErrorType.permission:
      case BackendErrorType.notFound:
        return AuthErrorType.service;
      case BackendErrorType.unknown:
        return AuthErrorType.unknown;
    }
  }

  Future<void> _handleGuestMode() async {
    setState(() {
      _isGuestLoading = true;
      _errorMessage = null;
      _errorType = null;
      _showRetryButton = false;
    });

    try {
      final result = await AuthService.instance.continueAsGuest();
      
      if (mounted) {
        if (result.success) {
          // Clear any previous errors on success
          setState(() {
            _errorMessage = null;
            _errorType = null;
            _showRetryButton = false;
            _retryAttempts = 0;
          });
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else {
          setState(() {
            _errorMessage = result.errorMessage ?? 'Failed to continue as guest. Please try again.';
            _errorType = result.errorType;
            _showRetryButton = result.isRetryable;
          });
        }
      }
    } on BackendException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.userMessage;
          _errorType = _mapBackendErrorType(e.errorType);
          _showRetryButton = e.isRetryable;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = BackendErrorHandler.getUserFriendlyMessage(e);
          _errorType = AuthErrorType.unknown;
          _showRetryButton = BackendErrorHandler.isRetryable(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isGuestLoading = false);
      }
    }
  }
}

class ErrorDisplayInfo {
  final String title;
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final Color textColor;
  final bool showTroubleshootingTip;
  final String troubleshootingTip;
  final Color tipBackgroundColor;
  final Color tipIconColor;
  final Color tipTextColor;

  ErrorDisplayInfo({
    required this.title,
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.textColor,
    required this.showTroubleshootingTip,
    required this.troubleshootingTip,
    required this.tipBackgroundColor,
    required this.tipIconColor,
    required this.tipTextColor,
  });
}