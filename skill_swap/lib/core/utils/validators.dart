String? validateEmail(String? v) {
  if (v == null || v.isEmpty) return 'Email is required';
  if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) return 'Enter a valid email';
  return null;
}

String? validatePassword(String? v) {
  if (v == null || v.isEmpty) return 'Password is required';
  if (v.length < 6) return 'Password must be at least 6 characters';
  return null;
}

String? validateRequired(String? v, [String field = 'This field']) {
  if (v == null || v.trim().isEmpty) return '$field is required';
  return null;
}
