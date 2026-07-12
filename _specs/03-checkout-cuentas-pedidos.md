# Spec 03 — Checkout sin pago, cuentas de usuario, historial de pedidos

Depende de: `01-wordpress-woocommerce-setup.md`. Todo esto es configuración de WooCommerce, no desarrollo custom.

## Checkout sin pasarela de pago
- En WooCommerce → Ajustes → Pagos: desactivar cualquier pasarela real (Stripe/PayPal etc. no se instalan).
- Activar método "Cheque" o "Transferencia bancaria directa" (o "Contra reembolso") renombrado a algo tipo "Pedido sin pago online — confirmación manual", con instrucciones claras en el texto del método.
- Resultado esperado: al finalizar checkout, el pedido queda en estado `on-hold` o `pending payment`, sin ningún cobro real.
- Página de "Pedido recibido" (thank-you de WooCommerce) muestra resumen y estado — no requiere desarrollo, es nativo.

## Cuentas de usuario
- WooCommerce → Ajustes → Cuentas y privacidad: permitir registro de clientes en la página "Mi cuenta", login habilitado.
- Página "Mi cuenta" (shortcode `[woocommerce_my_account]`, nativa) expone: datos de la cuenta, direcciones, y **Pedidos** (historial).
- Verificar que el flujo de invitado (checkout sin cuenta) también funciona si se quiere permitir, o forzar cuenta obligatoria antes de checkout — decidir y documentar la elección (recomendado: cuenta obligatoria para que el historial tenga sentido).

## Verificación end-to-end
- Crear cuenta nueva → añadir camiseta (con talla) al carrito → checkout con datos de envío → confirmar pedido sin pago → pedido visible en "Mi cuenta → Pedidos" con estado pendiente.
- Como admin, el pedido aparece en WooCommerce → Pedidos con el mismo estado y los datos de envío correctos.
