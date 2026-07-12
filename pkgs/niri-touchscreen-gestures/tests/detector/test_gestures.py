from niri_touchscreen_gestures.detector.classifiers import count_active_fingers


class TestClassifiers:
    def test_count_fingers(self):
        assert (
            count_active_fingers(
                {
                    0: {
                        "tracking_id": 167,
                        "start_x": 2404,
                        "start_y": 776,
                        "last_x": 1946,
                        "last_y": 717,
                    },
                    1: {
                        "tracking_id": -1,
                        "start_x": 0,
                        "start_y": 0,
                        "last_x": 0,
                        "last_y": 0,
                    },
                    2: {
                        "tracking_id": -1,
                        "start_x": 0,
                        "start_y": 0,
                        "last_x": 0,
                        "last_y": 0,
                    },
                    3: {
                        "tracking_id": -1,
                        "start_x": 0,
                        "start_y": 0,
                        "last_x": 0,
                        "last_y": 0,
                    },
                    4: {
                        "tracking_id": -1,
                        "start_x": 0,
                        "start_y": 0,
                        "last_x": 0,
                        "last_y": 0,
                    },
                    5: {
                        "tracking_id": -1,
                        "start_x": 0,
                        "start_y": 0,
                        "last_x": 0,
                        "last_y": 0,
                    },
                    6: {
                        "tracking_id": -1,
                        "start_x": 0,
                        "start_y": 0,
                        "last_x": 0,
                        "last_y": 0,
                    },
                    7: {
                        "tracking_id": -1,
                        "start_x": 0,
                        "start_y": 0,
                        "last_x": 0,
                        "last_y": 0,
                    },
                    8: {
                        "tracking_id": -1,
                        "start_x": 0,
                        "start_y": 0,
                        "last_x": 0,
                        "last_y": 0,
                    },
                    9: {
                        "tracking_id": -1,
                        "start_x": 0,
                        "start_y": 0,
                        "last_x": 0,
                        "last_y": 0,
                    },
                }
            )
            == 1
        )
