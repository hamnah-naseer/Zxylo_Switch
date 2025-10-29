import 'package:flutter/material.dart';
import 'package:ui_common/ui_common.dart';

import '../../../../core/services/firebase_service.dart';
import '../../../../core/shared/domain/entities/smart_room.dart';
import '../../../../core/shared/presentation/widgets/sh_app_bar.dart';
import '../../../auth/presentation/screens/add_room_screen.dart';
import '../widgets/lighted_background.dart';
import '../widgets/page_indicators.dart';
import '../widgets/smart_room_page_view.dart';
import '../screens/main_layout.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final controller = PageController(viewportFraction: 0.8);
  final ValueNotifier<double> pageNotifier = ValueNotifier(0);
  final ValueNotifier<int> roomSelectorNotifier = ValueNotifier(-1);

  @override
  void initState() {
    controller.addListener(pageListener);
    super.initState();
  }

  @override
  void dispose() {
    controller
      ..removeListener(pageListener)
      ..dispose();
    super.dispose();
  }

  void pageListener() {
    pageNotifier.value = controller.page ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return LightedBackgound(
      child: MainLayout( // ✅ use MainLayout (not main_layout)
        currentIndex: 0, // 👈 active tab (Home)
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              Text("SELECT A ROOM",
                style: context.bodyLarge.copyWith(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              ),
              height32,
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  clipBehavior: Clip.none,
                  children: [
                    StreamBuilder<List<SmartRoom>>(
                      stream: FirebaseService().getRoomsStream(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final rooms = snapshot.data!;

                        return SmartRoomsPageView(
                          pageNotifier: pageNotifier,
                          roomSelectorNotifier: roomSelectorNotifier,
                          controller: controller,
                          rooms: rooms,
                          onAddRoomTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AddRoomScreen()),
                            );
                          },
                        );
                      },
                    ),
                    Positioned.fill(
                      top: null,
                      child: Column(
                        children: [
                          PageIndicators(
                            roomSelectorNotifier: roomSelectorNotifier,
                            pageNotifier: pageNotifier,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
