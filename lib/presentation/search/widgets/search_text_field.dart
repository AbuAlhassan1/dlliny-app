import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/presentation/search/controllers/search_bloc.dart';

class SearchTextField extends StatefulWidget {
  const SearchTextField({super.key});

  @override
  State<SearchTextField> createState() => _SearchTextFieldState();
}

class _SearchTextFieldState extends State<SearchTextField> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.length < 2) {
      context.read<SearchBloc>().add(ClearSearch());
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      context.read<SearchBloc>().add(Search(query));
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final transparentBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    );
    return TextFormField(
      onChanged: _onChanged,
      style: TextStyle(color: c.onSurface),
      cursorColor: c.onSurface,
      decoration: InputDecoration(
        hintText: 'بحث',
        hintStyle: TextStyle(color: c.onSurfaceMuted),
        iconColor: c.onSurfaceSecondary,
        fillColor: c.surfaceMuted,
        filled: true,
        prefixIcon: Icon(Icons.search, color: c.onSurfaceSecondary),
        border: transparentBorder,
        enabledBorder: transparentBorder,
        focusedBorder: transparentBorder,
        errorBorder: transparentBorder,
      ),
    );
  }
}
