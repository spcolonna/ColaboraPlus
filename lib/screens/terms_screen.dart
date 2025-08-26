import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Estilos para reutilizar
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold);
    final paragraphStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Términos y Condiciones'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Términos y Condiciones de Uso - Colabora+',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Última actualización: 26 de agosto de 2025'),
            const SizedBox(height: 16),
            Text(
              'Bienvenido a Colabora+. Al descargar, instalar o utilizar esta aplicación (en adelante, "La Aplicación"), usted acepta estar sujeto a los siguientes términos y condiciones (en adelante, "Los Términos"). Si no está de acuerdo con alguno de estos términos, por favor, no utilice La Aplicación.',
              style: paragraphStyle,
              textAlign: TextAlign.justify,
            ),

            const SizedBox(height: 24),
            Text('1. Definiciones Clave', style: titleStyle),
            const SizedBox(height: 8),
            Text(
              '● La Aplicación / La Plataforma: Se refiere a la aplicación móvil "Colabora+".\n'
                  '● Administrador: Un usuario que crea, gestiona y es responsable de una o más rifas a través de La Aplicación.\n'
                  '● Participante: Un usuario que compra uno o más boletos en una rifa creada por un Administrador.\n'
                  '● Rifa: El evento creado por un Administrador con el fin de sortear uno o más premios.\n'
                  '● Boleto: El derecho a participar en una rifa, representado por uno o más números.',
              style: paragraphStyle,
            ),

            const SizedBox(height: 24),
            Text('2. Objeto de la Aplicación', style: titleStyle),
            const SizedBox(height: 8),
            Text(
              'Colabora+ es una plataforma tecnológica que sirve como intermediaria para conectar a Administradores que desean organizar rifas con Participantes que desean comprar boletos. Colabora+ no organiza, patrocina ni es responsable de ninguna de las rifas publicadas en la plataforma, más allá de proporcionar la herramienta tecnológica para su gestión.',
              style: paragraphStyle,
              textAlign: TextAlign.justify,
            ),

            const SizedBox(height: 24),
            Text('3. Obligaciones del Administrador', style: titleStyle),
            const SizedBox(height: 8),
            Text(
              'Al crear una rifa, el Administrador acepta y garantiza que:\n'
                  '● Es el único responsable de la veracidad, descripción, calidad y entrega de los premios ofrecidos.\n'
                  '● La rifa que organiza cumple con todas las leyes y regulaciones locales, estatales y nacionales aplicables.\n'
                  '● Se compromete a contactar a los ganadores y coordinar la entrega de los premios de manera oportuna una vez finalizado el sorteo.\n'
                  '● Para las compras con modalidad "Pago en Persona", es su exclusiva responsabilidad confirmar la recepción del pago marcando el boleto como "pagado" en La Aplicación. Los boletos no confirmados no participarán en el sorteo.',
              style: paragraphStyle,
            ),

            const SizedBox(height: 24),
            Text('4. Compra de Boletos por el Participante', style: titleStyle),
            const SizedBox(height: 8),
            Text(
              '● Los Participantes pueden comprar boletos a través de los métodos de pago ofrecidos.\n'
                  '● En la modalidad "Pago en Persona", el Participante entiende que su participación en el sorteo no está garantizada hasta que el Administrador de la rifa confirme manualmente la recepción del pago. Colabora+ no interviene ni se responsabiliza por transacciones realizadas fuera de la plataforma.\n'
                  '● Todas las compras de boletos son finales y no se realizarán reembolsos bajo ninguna circunstancia.',
              style: paragraphStyle,
            ),

            const SizedBox(height: 24),
            Text('5. Metodología del Sorteo y Transparencia', style: titleStyle),
            const SizedBox(height: 8),
            Text(
              'En Colabora+, la transparencia e imparcialidad del sorteo es nuestra máxima prioridad. Para garantizarlo, todos los sorteos se realizan de forma automática y sistemática siguiendo el siguiente proceso:\n\n'
                  '1. Activación Automática: El sorteo es ejecutado por un sistema automatizado (Cloud Function de Google) que se activa en los servidores de Google, no en el dispositivo del Administrador ni de ningún Participante. Esto asegura que nadie pueda influir en el inicio del proceso.\n\n'
                  '2. Hora del Sorteo: La función se ejecuta periódicamente. Cuando la fecha y hora programada por el Administrador para una rifa es alcanzada, el sistema identifica dicha rifa para iniciar el sorteo.\n\n'
                  '3. Selección de Boletos Válidos: El sistema realiza una consulta a la base de datos para recolectar únicamente los números de los boletos que estén marcados como "pagados" (`isPaid: true`). Los boletos con pagos pendientes no son incluidos en el sorteo.\n\n'
                  '4. Creación de la "Urna Virtual": Todos los números de los boletos válidos se agrupan en un "pool" o "urna virtual" única. Si un usuario compró los números 15 y 88, ambos números se introducen en la urna.\n\n'
                  '5. Selección Aleatoria de Ganadores: Para cada premio, desde el de mayor posición al de menor, el sistema selecciona un número de forma completamente aleatoria de la urna. Una vez que un número es seleccionado, es retirado permanentemente de la urna y no puede ser seleccionado para ningún otro premio.\n\n'
                  '6. Publicación de Resultados: Una vez finalizado el sorteo, los resultados se guardan permanentemente en la base de datos y se marcan como finales. El estado de la rifa cambia a "finalizado".\n\n'
                  'Este proceso automatizado garantiza que cada número pagado tenga exactamente la misma probabilidad de ganar y que el resultado sea imparcial.',
              style: paragraphStyle,
              textAlign: TextAlign.justify,
            ),

            const SizedBox(height: 24),
            Text('6. Limitación de Responsabilidad', style: titleStyle),
            const SizedBox(height: 8),
            Text(
              'Colabora+ es una plataforma intermediaria. No nos responsabilizamos por:\n'
                  '● Disputas entre Administradores y Participantes.\n'
                  '● La no entrega o la calidad de los premios.\n'
                  '● La legalidad de las rifas publicadas por los Administradores.',
              style: paragraphStyle,
            ),

            const SizedBox(height: 24),
            Text('7. Ley Aplicable y Jurisdicción', style: titleStyle),
            const SizedBox(height: 8),
            Text(
              'Estos Términos se regirán e interpretarán de acuerdo con las leyes de Uruguay. Cualquier disputa que surja en relación con estos Términos estará sujeta a la jurisdicción exclusiva de los tribunales de Uruguay.',
              style: paragraphStyle,
              textAlign: TextAlign.justify,
            ),

            const SizedBox(height: 24),
            Text('8. Contacto', style: titleStyle),
            const SizedBox(height: 8),
            Text(
              'Si tienes alguna pregunta sobre estos Términos y Condiciones, puedes contactarnos en: [Email de Contacto Próximamente]',
              style: paragraphStyle,
            ),
          ],
        ),
      ),
    );
  }
}
