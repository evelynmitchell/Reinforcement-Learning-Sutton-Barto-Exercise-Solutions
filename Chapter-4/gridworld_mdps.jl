include("mdp_solutions.jl")

@enum Action up down left right

#p should be a dictionary mapping state/action pairs to a distribution over state/reward pairs
function form_gridworld4x4_mdp()
    states = 1:14
    actions = [up, down, left, right]
    rewards = [-1]
    s_term = 0

    sa_pairs = ((s, a) for s in states for a in actions)

    #defines the properties of each of the 4 actions by 1. the state(s) that lead to a terminal state, 2. the states that leave the original state unchanges, and 3. the default state transition 
    actionprops = Dict([
        right => (Set([14]), Set([3, 7, 11]), s -> s + 1),
        left => (Set([1]), Set([4, 8, 12]), s -> s - 1),
        up => (Set([4]), Set([1, 2, 3]), s -> s - 4),
        down => (Set([11]), Set([12, 13, 14]), s -> s + 4)
    ])

    #convert a single state into a distribution over states
    makedist(s) = reshape(Float64.(s .== states), length(states), length(rewards))

    #generate a new state distribution from state action pair, since there is only one reward value, this is just a vector but in general could be a matrix
    function move(s, a)
        (s1, s2, f) = actionprops[a]
        snew =  in(s, s1) ? s_term  :
                in(s, s2) ? s       : 
                f(s)
        makedist(snew)
    end

    # ptr = Dict(s => Dict(a => move(s, a) for a in actions) for s in states)
    ptr = mapreduce(s -> mapreduce(a -> move(s,a), (a,b) -> cat(a,b,dims=4), actions), (a,b) -> cat(a,b,dims=3), states)
    # ptr = foldl((a,b) -> cat(a,b,dims=3), states |> Map(s -> foldl((a,b) -> cat(a,b,dims=4), Map(a -> move(s,a)), actions)))
    # ptr = mapreduce(Map(s -> mapreduce(Map(a -> move(s,a)), (a,b) -> cat(a,b,dims=3), actions)), (a,b) -> cat(a,b,dims=4), states)
    # [[move(s,a) for a in a?catctions] for s in states]
    (ptr = ptr, states = states, actions = actions, rewards = rewards)

    # dists = (move(sa...) for sa in sa_pairs)
    # Dict(zip(sa_pairs, dists))
end

function run_4x4gridworld(nmax=Inf)
    gridworldmdp = form_gridworld4x4_mdp()
    π_rand = form_random_policy(gridworldmdp)
    V = policy_eval(π_rand, eps(0.0), gridworldmdp, 1.0, nmax = nmax)
end

function form_gridworld_modified_mdp()
    states = 1:15
    actions = [up, down, left, right]
    rewards = [-1]
    s_term = 0

    sa_pairs = ((s, a) for s in states for a in actions)

    #defines the properties of each of the 4 actions by 1. the state(s) that lead to a terminal state, 2. the states that leave the original state unchanges, and 3. the default state transition 
    actionprops = Dict([
        right => (Set([14]), Set([3, 7, 11]), Dict([15 => 14]), s -> s + 1),
        left => (Set([1]), Set([4, 8, 12]), Dict([15 => 12]), s -> s - 1),
        up => (Set([4]), Set([1, 2, 3]), Dict([15 => 13]), s -> s - 4),
        down => (Set([11]), Set([12, 15, 14]), Dict([13 => 15]), s -> s + 4)
    ])

    #convert a single state into a distribution over states
    makedist(s) = reshape(Float64.(s .== states), length(states), length(rewards))

    #generate a new state distribution from state action pair, since there is only one reward value, this is just a vector but in general could be a matrix
    function move(s, a)
        (s1, s2, s3, f) = actionprops[a]
        snew =  in(s, s1) ? s_term      :
                in(s, s2) ? s           :
                haskey(s3, s) ? s3[s]   : 
                f(s)
        makedist(snew)
    end

    # ptr = Dict(s => Dict(a => move(s, a) for a in actions) for s in states)
    ptr = mapreduce(s -> mapreduce(a -> move(s,a), (a,b) -> cat(a,b,dims=4), actions), (a,b) -> cat(a,b,dims=3), states)
    # ptr = foldl((a,b) -> cat(a,b,dims=3), states |> Map(s -> foldl((a,b) -> cat(a,b,dims=4), Map(a -> move(s,a)), actions)))
    # ptr = mapreduce(Map(s -> mapreduce(Map(a -> move(s,a)), (a,b) -> cat(a,b,dims=3), actions)), (a,b) -> cat(a,b,dims=4), states)
    # [[move(s,a) for a in a?catctions] for s in states]
    (ptr = ptr, states = states, actions = actions, rewards = rewards)

    # dists = (move(sa...) for sa in sa_pairs)
    # Dict(zip(sa_pairs, dists))
end

function run_modifiedgridworld(nmax=Inf)
    mdp = form_gridworld_modified_mdp()
    π_rand = form_random_policy(mdp)
    V = policy_eval(π_rand, eps(0.0), mdp, 1.0, nmax = nmax)
end

function gridworld_policy_iteration(itermax=10; evaln = Inf, θ=eps(0.0), γ=1.0)
	mdp = form_gridworld4x4_mdp()
	π_rand = form_random_policy(mdp)
	(policy_stable, resultlist) = begin_policy_iteration(mdp, π_rand, γ, evaln = evaln, iters = itermax)
	(Vstar, πstar) = resultlist[end]
	(policy_stable, Vstar, [argmax(πstar[s]) for s in mdp.states])
end