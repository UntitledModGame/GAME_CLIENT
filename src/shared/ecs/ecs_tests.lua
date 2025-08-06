
-- tests are disabled by default, since our ECS has global/static state
local DO_TESTS = true

if (not DO_TESTS) then return end



-- ECS API Test Suite
ecs.defineComponent("shared")
ecs.defineEntityType("test", {
    shared = true
})

ecs.defineComponent("foo")
ecs.defineComponent("bar")


do -- Basic flush behavior
    local v = ecs.view("foo")
    local e = ecs.newEntity("test")

    assert(v:size() == 0)
    e:addComponent("foo", 42)
    assert(v:size() == 0)
    ecs.flush()
    assert(v:size() == 1)

    ecs.clear()
end


do -- Entity deletion removes from views
    local v = ecs.view("foo")
    local e = ecs.newEntity("test")

    e:addComponent("foo", 42)
    ecs.flush()
    assert(v:size() == 1)

    e:delete()
    assert(v:size() == 1)
    ecs.flush()
    assert(v:size() == 0)

    assert(e:isDeleted())
    ecs.clear()
end


do -- Referenced entity deletion
    local e1 = ecs.newEntity("test")
    local e2 = ecs.newEntity("test")

    e1.foo = e2
    e1:delete()

    ecs.flush()

    assert(getmetatable(e1) == getmetatable(e2))
    assert(e2:isDeleted())
    assert(e1:isDeleted())

    ecs.clear()
end



do -- View caching
    local v1 = ecs.view("bar")
    local v2 = ecs.view("bar")
    assert(v1 == v2)
    ecs.clear()
end

do -- __newindex same as addComponent
    ecs.defineComponent("health")
    local v = ecs.view("health")
    local e = ecs.newEntity("test")

    e.health = 100
    ecs.flush()
    assert(v:size() == 1)
    assert(e.health == 100)

    ecs.clear()
end

do -- Component removal
    ecs.defineComponent("weapon")
    local v = ecs.view("weapon")
    local e = ecs.newEntity("test",0,0)

    e.weapon = "sword"
    assert(v:size() == 0)
    ecs.flush()
    assert(v:size() == 1)

    e:removeComponent("weapon")
    assert(v:size() == 1)
    ecs.flush()
    assert(v:size() == 0)

    ecs.clear()
end

do -- Shared components
    ecs.defineEntityType("etype1", {
        shared = {}
    })

    local e1 = ecs.newEntity("etype1")
    local e2 = ecs.newEntity("etype1")
    assert(e1.shared == e2.shared)
    assert(e1 ~= e2)
    assert(e1:isSharedComponent("shared"))
    assert(not e1:isRegularComponent("shared"))

    ecs.clear()
end

do -- Shared to regular transformation
    ecs.defineComponent("data")
    ecs.defineEntityType("etype2", {
        data = {value = 10}
    })

    local e1 = ecs.newEntity("etype2")
    local e2 = ecs.newEntity("etype2")
    assert(e1.data == e2.data)
    assert(e1:isSharedComponent("data"))

    e1.data = {value = 20}
    assert(e1.data ~= e2.data)
    assert(e1:isRegularComponent("data"))
    assert(e2:isSharedComponent("data"))

    ecs.clear()
end

do -- Regular back to shared via removeComponent
    ecs.defineComponent("score")
    ecs.defineEntityType("etype3", {
        score = 0
    })

    local e1 = ecs.newEntity("etype3")
    local e2 = ecs.newEntity("etype3")

    e1.score = 100  -- Make regular
    assert(e1:isRegularComponent("score"))

    e1:removeComponent("score")  -- Should revert to shared
    assert(e1:isSharedComponent("score"))
    assert(e1.score == e2.score)

    ecs.clear()
end


do -- Add-remove-add inbetween flushes
    ecs.defineComponent("temp")
    local v = ecs.view("temp")
    local e = ecs.newEntity("test")

    e:addComponent("temp", 0)
    e:removeComponent("temp")
    e:addComponent("temp", 1)

    ecs.flush()
    assert(v:size() == 1)
    assert(e.temp == 1)

    ecs.clear()
end


do -- Add-then-remove (should not be in view)
    ecs.defineComponent("volatile")
    local v = ecs.view("volatile")
    local e = ecs.newEntity("test")

    e:addComponent("volatile", 42)
    e:removeComponent("volatile")

    ecs.flush()
    assert(v:size() == 0)

    ecs.clear()
end



error("Tests passed! (yay)")

