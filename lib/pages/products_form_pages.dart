import 'package:app_01/models/products.dart';
import 'package:app_01/services/products_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProductFormPage extends StatefulWidget {
  final Products? product;
  const ProductFormPage({super.key, this.product});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

/// Formateador de precio: solo dígitos y UNA coma decimal.
/// Máximo 4 dígitos enteros + 2 decimales (6 dígitos en total).
/// Una vez alcanzado el límite, bloquea físicamente que se siga escribiendo.
class _PriceInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;

    // Solo se permiten dígitos y comas.
    text = text.replaceAll(RegExp(r'[^0-9,]'), '');

    // Como máximo UNA coma: se elimina cualquier coma adicional.
    final firstComma = text.indexOf(',');
    if (firstComma != -1) {
      text =
          text.substring(0, firstComma + 1) +
          text.substring(firstComma + 1).replaceAll(',', '');
    }

    final parts = text.split(',');
    var integerPart = parts[0];
    String? decimalPart = parts.length > 1 ? parts[1] : null;

    // Máximo 4 dígitos enteros antes de la coma.
    if (integerPart.length > 4) {
      integerPart = integerPart.substring(0, 4);
    }

    // Máximo 2 dígitos decimales después de la coma.
    if (decimalPart != null && decimalPart.length > 2) {
      decimalPart = decimalPart.substring(0, 2);
    }

    final result = decimalPart != null
        ? '$integerPart,$decimalPart'
        : integerPart;

    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}

class _CapitalizeWordsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    final buffer = StringBuffer();
    bool capitalizeNext = true;

    for (var i = 0; i < text.length; i++) {
      final char = text[i];
      if (char == ' ') {
        buffer.write(char);
        capitalizeNext = true;
      } else if (capitalizeNext) {
        buffer.write(char.toUpperCase());
        capitalizeNext = false;
      } else {
        buffer.write(char.toLowerCase());
      }
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: newValue.selection,
    );
  }
}

/// Teclas que se bloquean dentro de los campos del formulario:
/// Tab, Caps Lock, Shift, Ctrl, Fn, Windows/Meta y Alt.
/// Se consume el evento (KeyEventResult.handled) para que no dispare
/// su acción por defecto (Tab ya no cambia el foco de campo, por ejemplo).
///
/// [extraChars] permite que un campo específico habilite caracteres
/// adicionales (por ejemplo, la coma decimal en el campo de precio) sin
/// afectar a los demás campos del formulario.
bool _isAllowedKey(LogicalKeyboardKey key, {String extraChars = ''}) {
  if (key == LogicalKeyboardKey.space ||
      key == LogicalKeyboardKey.backspace ||
      key == LogicalKeyboardKey.delete) {
    return true;
  }

  final label = key.keyLabel;
  // keyLabel de letras/dígitos es un solo carácter alfanumérico
  // ("A", "5", etc). Cualquier otra tecla especial tiene un keyLabel
  // distinto (más largo o vacío), así que queda bloqueada.
  if (label.length != 1) return false;

  if (extraChars.contains(label)) return true;

  final code = label.codeUnitAt(0);
  final isLetter = (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
  final isDigit = code >= 48 && code <= 57;
  return isLetter || isDigit;
}

KeyEventResult _blockRestrictedKeys(
  FocusNode node,
  KeyEvent event, {
  String extraChars = '',
}) {
  if (!_isAllowedKey(event.logicalKey, extraChars: extraChars)) {
    return KeyEventResult.handled;
  }
  return KeyEventResult.ignored;
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();

  final namesController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();

  final ProductsService productsService = ProductsService();

  bool _isSaving = false;

  // Se marca en true en cuanto el usuario modifica algún campo, para poder
  // preguntar antes de salir sin guardar.
  bool _dirty = false;

  // Versión "viva" del producto que se está editando. Empieza con la del
  // widget, pero se actualiza cuando se resuelve un conflicto cargando los
  // datos actuales del servidor: de lo contrario, tras un conflicto la
  // siguiente actualización siempre volvería a chocar (quedaría comparando
  // contra una versión vieja para siempre).
  late int _currentVersion;

  // Solo letras (con tildes/ñ) y espacios. Sin números ni caracteres especiales.
  static final RegExp _nameAllowed = RegExp(r'^[a-zA-Z0-9À-ÿ ]+$');

  @override
  void initState() {
    super.initState();
    _currentVersion = widget.product?.version ?? 0;
    if (widget.product != null) {
      namesController.text = widget.product!.names;
      priceController.text = widget.product!.price
          .toStringAsFixed(2)
          .replaceAll('.', ',');
      stockController.text = widget.product!.stock.toString();
    }
    namesController.addListener(_markDirty);
    priceController.addListener(_markDirty);
    stockController.addListener(_markDirty);
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  @override
  void dispose() {
    namesController.dispose();
    priceController.dispose();
    stockController.dispose();
    super.dispose();
  }

  /// Pregunta al usuario si desea dejar de editar cuando hay cambios sin
  /// guardar y presiona "atrás" (gesto, botón del sistema o flecha del
  /// AppBar). Devuelve true si debe salir de la pantalla.
  Future<bool> _confirmDiscardIfDirty() async {
    if (!_dirty) return true;

    final leave = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('¿Dejar de editar?'),
          content: const Text(
            'Tiene cambios sin guardar. Si sale ahora, se perderán.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Seguir editando'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Descartar cambios'),
            ),
          ],
        ),
      ),
    );

    return leave ?? false;
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre es obligatorio.';
    }
    if (value.trim().length > 55) {
      return 'El nombre no puede superar los 55 caracteres.';
    }
    if (!_nameAllowed.hasMatch(value.trim())) {
      return 'Solo se permiten letras, números y espacios (sin caracteres especiales).';
    }
    return null;
  }

  String? _validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El precio es obligatorio.';
    }
    final normalized = value.trim().replaceAll(',', '.');
    final parsed = double.tryParse(normalized);
    if (parsed == null) {
      return 'Ingrese un número válido.';
    }
    if (parsed <= 0) {
      return 'El precio debe ser mayor a 0.';
    }
    if (parsed > 9999.99) {
      return 'Máximo 4 enteros y 2 decimales (hasta 9999,99).';
    }
    return null;
  }

  String? _validateStock(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El stock es obligatorio.';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      return 'Ingrese un número entero válido.';
    }
    // El stock nunca puede ser 0 (ni negativo).
    if (parsed <= 0) {
      return 'El stock debe ser mayor a 0 (no puede ser 0).';
    }
    if (parsed > 99999) {
      return 'El stock no puede tener más de 5 dígitos.';
    }
    return null;
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _handleConflict(ConflictException e) async {
    if (!mounted) return;
    final refresh = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // no se cierra tocando afuera
      builder: (context) => PopScope(
        canPop: false, // bloquea Escape / botón de retroceso
        child: AlertDialog(
          title: const Text('Conflicto de datos'),
          content: Text(
            '${e.message}\n\n'
            'Otro usuario cambió este producto mientras usted lo editaba.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cerrar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Cargar datos actuales'),
            ),
          ],
        ),
      ),
    );

    if (refresh == true && e.current != null && mounted) {
      setState(() {
        namesController.text = e.current!.names;
        priceController.text = e.current!.price
            .toStringAsFixed(2)
            .replaceAll('.', ',');
        stockController.text = e.current!.stock.toString();
        // Clave del fix: se toma la versión ACTUAL del servidor, si no la
        // próxima actualización seguiría comparando contra la versión vieja
        // y volvería a chocar aunque los datos ya estén al día.
        _currentVersion = e.current!.version;
        // Los campos ahora reflejan exactamente lo que hay en el servidor.
        _dirty = false;
      });
    }
  }

  Future<void> saveUpdateProduct() async {
    if (!_formKey.currentState!.validate()) {
      _showMessage('Revise los campos marcados en rojo.', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    final product = Products(
      id: widget.product?.id ?? '0',
      names: namesController.text.trim(),
      price: double.parse(priceController.text.trim().replaceAll(',', '.')),
      stock: int.parse(stockController.text.trim()),
      version: _currentVersion,
    );

    try {
      if (widget.product != null) {
        final updated = await productsService.updateProduct(product);
        _currentVersion = updated.version;
        _showMessage('Producto actualizado correctamente.');
      } else {
        await productsService.createProduct(product);
        _showMessage('Producto creado correctamente.');
      }

      _dirty = false;
      if (mounted) {
        Navigator.pop(context, true);
      }
    } on ConflictException catch (e) {
      await _handleConflict(e);
    } on ApiException catch (e) {
      _showMessage(e.message, isError: true);
    } catch (e) {
      _showMessage('Ocurrió un error inesperado: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;

    return PopScope(
      // Si no hay cambios sin guardar (o ya se guardó), se puede salir
      // directamente. Si hay cambios, se intercepta el pop para preguntar.
      canPop: !_dirty,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldLeave = await _confirmDiscardIfDirty();
        if (shouldLeave && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Editar Producto' : 'Agregar Producto'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Focus(
                  onKeyEvent: _blockRestrictedKeys,
                  child: TextFormField(
                    controller: namesController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del producto',
                      border: OutlineInputBorder(),
                      helperText: 'Solo letras, números y espacios (máx. 55)',
                    ),
                    maxLength: 55,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    // Bloquea físicamente cualquier tecla que no sea letra/espacio,
                    // incluso si viene de pegar texto. Los números quedan excluidos.
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[a-zA-Z0-9À-ÿ ]'),
                      ),
                      _CapitalizeWordsFormatter(),
                    ],
                    validator: _validateName,
                  ),
                ),
                const SizedBox(height: 15),
                Focus(
                  // Este campo habilita la coma como carácter extra, ya que
                  // es el separador decimal del precio.
                  onKeyEvent: (node, event) =>
                      _blockRestrictedKeys(node, event, extraChars: ','),
                  child: TextFormField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: 'Precio',
                      border: OutlineInputBorder(),
                      helperText:
                          'Máx. 4 enteros + 2 decimales, use coma (ej: 199,99)',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [_PriceInputFormatter()],
                    validator: _validatePrice,
                  ),
                ),
                const SizedBox(height: 15),
                Focus(
                  onKeyEvent: _blockRestrictedKeys,
                  child: TextFormField(
                    controller: stockController,
                    decoration: const InputDecoration(
                      labelText: 'Stock',
                      border: OutlineInputBorder(),
                      helperText: 'Solo números, mayor a 0 (máx. 5 dígitos)',
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 5,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: _validateStock,
                  ),
                ),
                const SizedBox(height: 25),
                ElevatedButton(
                  onPressed: _isSaving ? null : saveUpdateProduct,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isEditing ? 'Actualizar' : 'Guardar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}