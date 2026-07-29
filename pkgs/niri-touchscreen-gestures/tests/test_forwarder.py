import subprocess

import pytest

from niri_touchscreen_gestures import forwarder


class FakeRun:
    def __init__(self):
        self.calls = []

    def __call__(self, args, **kwargs):
        self.calls.append((args, kwargs))


@pytest.fixture
def fake_run(monkeypatch):
    fake = FakeRun()
    monkeypatch.setattr(forwarder.subprocess, "run", fake)
    return fake


def test_send_click_at_left_moves_then_clicks(fake_run):
    forwarder.send_click_at("left", 100, 200)
    assert fake_run.calls == [
        (["ydotool", "mousemove", "--absolute", "--", "100", "200"], {"check": True}),
        (["ydotool", "click", "0xC0"], {"check": True}),
    ]


def test_send_click_at_right_uses_0xc1(fake_run):
    forwarder.send_click_at("right", 5, 6)
    assert fake_run.calls[1] == (["ydotool", "click", "0xC1"], {"check": True})


def test_send_scroll_positive_delta(fake_run):
    forwarder.send_scroll(5.0)
    assert fake_run.calls == [(["wlrctl", "pointer", "scroll", "5.0"], {"check": True})]


def test_send_scroll_negative_delta_not_absolute_valued(fake_run):
    forwarder.send_scroll(-2.5)
    assert fake_run.calls == [(["wlrctl", "pointer", "scroll", "-2.5"], {"check": True})]


def test_send_click_at_propagates_subprocess_failure(monkeypatch):
    def raise_called_process_error(args, **kwargs):
        raise subprocess.CalledProcessError(1, args)

    monkeypatch.setattr(forwarder.subprocess, "run", raise_called_process_error)
    with pytest.raises(subprocess.CalledProcessError):
        forwarder.send_click_at("left", 0, 0)
