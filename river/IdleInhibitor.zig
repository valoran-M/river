const Self = @This();

const std = @import("std");
const wlr = @import("wlroots");
const wl = @import("wayland").server.wl;

const server = &@import("main.zig").server;
const util = @import("util.zig");

const IdleInhibitorManager = @import("IdleInhibitorManager.zig");

inhibitor_manager: *IdleInhibitorManager,
inhibitor: *wlr.IdleInhibitorV1,
destroy: wl.Listener(*wlr.Surface) = wl.Listener(*wlr.Surface).init(handleDestroy),

pub fn init(self: *Self, inhibitor: *wlr.IdleInhibitorV1, inhibitor_manager: *IdleInhibitorManager) !void {
    self.inhibitor_manager = inhibitor_manager;
    self.inhibitor = inhibitor;
    self.destroy.setNotify(handleDestroy);
    inhibitor.events.destroy.add(&self.destroy);

    inhibitor_manager.idleInhibitCheckActive();
}

fn handleDestroy(listener: *wl.Listener(*wlr.Surface), _: *wlr.Surface) void {
    const self = @fieldParentPtr(Self, "destroy", listener);
    self.destroy.link.remove();

    const node = @fieldParentPtr(std.TailQueue(Self).Node, "data", self);
    server.idle_inhibitor_manager.inhibitors.remove(node);

    self.inhibitor_manager.idleInhibitCheckActive();

    util.gpa.destroy(node);
}
