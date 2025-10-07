// lib/screens/messages/messages_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/message.dart';
import '../../providers/message_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/messages/message_card.dart';
import '../../widgets/messages/bandeja_selector.dart';
import '../../services/permission_service.dart';
import '../mensajes/create_message_screen.dart';

/// 📨 PANTALLA PRINCIPAL DE MENSAJES
/// Lista de mensajes con 5 bandejas + búsqueda + FAB crear mensaje
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadInitialMessages();
    _setupScrollListener();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ========================================
  // 🔧 INICIALIZACIÓN
  // ========================================

  void _loadInitialMessages() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final messageProvider = context.read<MessageProvider>();

      // 🔐 VALIDAR QUE LA BANDEJA ACTUAL SEA ACCESIBLE
      final bandejaActual = messageProvider.currentBandeja;
      final canSendMasive =
          PermissionService.canAccess('mensajes.enviar_masivo');

      // Si es ESTUDIANTE/ACUDIENTE y está en una bandeja no permitida
      if (!canSendMasive) {
        final bandejaPermitidas = [
          Bandeja.recibidos,
          Bandeja.enviados,
          Bandeja.archivados, // ← AGREGAR
          Bandeja.eliminados, // ← AGREGAR
        ];

        // Solo bloquear BORRADORES para ESTUDIANTES/ACUDIENTES
        if (bandejaActual == Bandeja.borradores) {
          print('⚠️ Usuario sin permiso para ver borradores');
          print('✅ Cambiando a bandeja "Recibidos"');
          messageProvider.changeBandeja(Bandeja.recibidos);
          return;
        }
      }

      // Cargar mensajes de la bandeja actual
      messageProvider.loadMessages(bandejaActual);
    });
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMoreMessages();
      }
    });
  }

  void _loadMoreMessages() {
    final messageProvider = context.read<MessageProvider>();
    final currentMeta = messageProvider.currentMeta;
    final currentPage = currentMeta['pagina'] ?? 1;
    final totalPages = currentMeta['totalPaginas'] ?? 1;

    if (currentPage < totalPages && !messageProvider.isLoading) {
      messageProvider.loadMessages(
        messageProvider.currentBandeja,
        page: currentPage + 1,
      );
    }
  }

  // ========================================
  // 🔄 ACCIONES
  // ========================================

  Future<void> _onRefresh() async {
    final messageProvider = context.read<MessageProvider>();
    await messageProvider.loadMessages(
      messageProvider.currentBandeja,
      refresh: true,
    );
  }

  void _onBandejaChanged(Bandeja newBandeja) {
    final messageProvider = context.read<MessageProvider>();

    // 🔐 VALIDAR PERMISO ANTES DE CAMBIAR
    final canSendMasive = PermissionService.canAccess('mensajes.enviar_masivo');

    if (!canSendMasive) {
      // Solo bloquear BORRADORES
      if (newBandeja == Bandeja.borradores) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No tienes permisos para crear borradores'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
    }

    messageProvider.changeBandeja(newBandeja);
  }

  void _onSearch(String query) {
    final messageProvider = context.read<MessageProvider>();
    if (query.isEmpty) {
      messageProvider.clearSearch();
    } else {
      messageProvider.search(query);
    }
  }

  void _onMessageTap(Message message) {
    if (message.isDraft) {
      // ✅ Navegar a editar borrador
      print('✏️ Editar borrador: ${message.id}');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateMessageScreen(
            originalMessage: message,
            isDraftEdit: true,
          ),
        ),
      );
    } else {
      // Navegar a detalle de mensaje
      context.push('/mensajes/${message.id}');
    }
  }

  void _onCreateMessage() {
    context.push('/mensajes/create');
    //print('🔧 TODO: Navegar a crear mensaje');
    // Navigator.pushNamed(context, '/messages/create');
  }

  // ========================================
  // 🎨 UI
  // ========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mensajes'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Consumer<MessageProvider>(
            builder: (context, messageProvider, _) {
              return BandejaSelector(
                selectedBandeja: messageProvider.currentBandeja,
                onBandejaChanged: _onBandejaChanged,
                counts: {
                  Bandeja.recibidos:
                      messageProvider.getTotalForBandeja(Bandeja.recibidos),
                  Bandeja.enviados:
                      messageProvider.getTotalForBandeja(Bandeja.enviados),
                  Bandeja.borradores:
                      messageProvider.getTotalForBandeja(Bandeja.borradores),
                  Bandeja.archivados:
                      messageProvider.getTotalForBandeja(Bandeja.archivados),
                  Bandeja.eliminados:
                      messageProvider.getTotalForBandeja(Bandeja.eliminados),
                },
              );
            },
          ),
        ),
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          _buildSearchBar(),

          // Lista de mensajes
          Expanded(
            child: Consumer<MessageProvider>(
              builder: (context, messageProvider, _) {
                final messages = messageProvider.currentMessages;
                final isLoading = messageProvider.isLoading;
                final bandeja = messageProvider.currentBandeja;

                if (isLoading && messages.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (messages.isEmpty) {
                  return _buildEmptyState(bandeja);
                }

                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: ListView.separated(
                    controller: _scrollController,
                    itemCount: messages.length + (isLoading ? 1 : 0),
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      if (index == messages.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final message = messages[index];
                      final authProvider = context.read<AuthProvider>();
                      final currentUserId = authProvider.currentUser?.id;

                      return MessageCard(
                        message: message,
                        bandeja: bandeja,
                        currentUserId: currentUserId,
                        onTap: () => _onMessageTap(message),
                        onArchive: bandeja != Bandeja.archivados
                            ? () => _handleArchive(message.id)
                            : null,
                        onUnarchive: bandeja == Bandeja.archivados
                            ? () => _handleUnarchive(message.id)
                            : null,
                        onDelete: bandeja != Bandeja.eliminados
                            ? () => _handleDelete(message.id)
                            : null,
                        onRestore: bandeja == Bandeja.eliminados
                            ? () => _handleRestore(message.id)
                            : null,
                        onDeletePermanently: bandeja == Bandeja.eliminados
                            ? () => _handleDeletePermanently(message.id)
                            : null,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onCreateMessage,
        child: const Icon(Icons.edit),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearch,
        decoration: InputDecoration(
          hintText: 'Buscar mensajes...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _onSearch('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Bandeja bandeja) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              bandeja.icon,
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(
              bandeja.emptyMessage,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              bandeja.emptySubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // 🔧 ACCIONES DE MENSAJES
  // ========================================

  void _handleArchive(String messageId) async {
    try {
      await context.read<MessageProvider>().archiveMessage(messageId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mensaje archivado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al archivar: $e')),
        );
      }
    }
  }

  void _handleUnarchive(String messageId) async {
    try {
      await context.read<MessageProvider>().unarchiveMessage(messageId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mensaje desarchivado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al desarchivar: $e')),
        );
      }
    }
  }

  void _handleDelete(String messageId) async {
    try {
      await context.read<MessageProvider>().deleteMessage(messageId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mensaje movido a papelera')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e')),
        );
      }
    }
  }

  void _handleRestore(String messageId) async {
    try {
      await context.read<MessageProvider>().restoreMessage(messageId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mensaje restaurado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al restaurar: $e')),
        );
      }
    }
  }

  void _handleDeletePermanently(String messageId) async {
    try {
      await context.read<MessageProvider>().deletePermanently(messageId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mensaje eliminado permanentemente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e')),
        );
      }
    }
  }
}
