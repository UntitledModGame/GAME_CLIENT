
local DO_TESTS = false

if (not DO_TESTS) then return end



-- ECS API Test Suite

do -- test1: Basic flush behavior
    ecs.defineComponent("foo")
    local v = ecs.view("foo")
    local e = ecs.newEntity("myEnt")
    
    assert(v:size() == 0)
    e:addComponent("foo", 42)
    assert(v:size() == 0)
    ecs.flush()
    assert(v:size() == 1)
    
    ecs.clear()
end

do -- test2: View caching
    ecs.defineComponent("bar")
    local v1 = ecs.view("bar")
    local v2 = ecs.view("bar")
    assert(v1 == v2)
    
    ecs.clear()
end

do -- test3: Direct assignment
    ecs.defineComponent("health")
    local v = ecs.view("health")
    local e = ecs.newEntity("player")
    
    e.health = 100
    ecs.flush()
    assert(v:size() == 1)
    assert(e.health == 100)
    
    ecs.clear()
end

do -- test4: Component removal
    ecs.defineComponent("weapon")
    local v = ecs.view("weapon")
    local e = ecs.newEntity("soldier")
    
    e.weapon = "sword"
    ecs.flush()
    assert(v:size() == 1)
    
    e:removeComponent("weapon")
    ecs.flush()
    assert(v:size() == 0)
    
    ecs.clear()
end

do -- test5: Shared components
    ecs.defineComponent("comp")
    ecs.defineEntityType("etype1", {
        comp = {}
    })
    
    local e1 = ecs.newEntity("etype1")
    local e2 = ecs.newEntity("etype1")
    assert(e1.comp == e2.comp)
    assert(e1:isSharedComponent("comp"))
    assert(not e1:isRegularComponent("comp"))
    
    ecs.clear()
end

do -- test6: Shared to regular transformation
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

do -- test7: Regular back to shared via removeComponent
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

do -- test8: Shared component mutation
    ecs.defineComponent("config")
    ecs.defineEntityType("etype4", {
        config = {level = 1}
    })
    
    local e1 = ecs.newEntity("etype4")
    local e2 = ecs.newEntity("etype4")
    
    e1.config.level = 5  -- Mutate shared table
    assert(e2.config.level == 5)  -- Should affect both
    
    ecs.clear()
end

do -- test9: Add-remove-add sequence
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

do -- test10: Add-remove sequence (should not be in view)
    ecs.defineComponent("volatile")
    local v = ecs.view("volatile")
    local e = ecs.newEntity("test")
    
    e:addComponent("volatile", 42)
    e:removeComponent("volatile")
    
    ecs.flush()
    assert(v:size() == 0)
    
    ecs.clear()
end
