import 'package:flutter/material.dart';
import 'package:ui_common/ui_common.dart';

import '../../../../core/services/firebase_service.dart';
import '../../../../core/shared/domain/entities/smart_room.dart';
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
      child: MainLayout(
        currentIndex: 0,
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
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              "Error loading rooms: ${snapshot.error}",
                              style: const TextStyle(color: Colors.red),
                            ),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text(
                              "No rooms found 😔",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          );
                        }

                        final rooms = snapshot.data!;
                        print(" Rooms fetched: ${rooms.length}");

                        return SmartRoomsPageView(
                          pageNotifier: pageNotifier,
                          roomSelectorNotifier: roomSelectorNotifier,
                          controller: controller,
                          rooms: rooms,
                          onAddRoomTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => AddRoomScreen(onRoomAdded: (Map<String, dynamic> p1) {  },)),
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
