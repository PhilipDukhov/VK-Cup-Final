//
//  Runtime.swift
//  
//
//  Created by Philip Dukhov on 10/27/20.
//

import Foundation

typealias Dispatch<Msg> = (Msg) -> Void
typealias Effect<Msg> = (@escaping Dispatch<Msg>) -> Void

private let _runtimeQueue = DispatchQueue(label: "ElmRuntimeQueue")
private let _renderQueue = DispatchQueue(label: "ElmRenderQueue")
private let _effectQueue = DispatchQueue(label: "ElmEffectQueue")

class Runtime<Model, Msg, Props> {
    let update: (Msg, Model) -> (Model, Effect<Msg>?)
    let view: (Model) -> Props
    let render: (Props, Dispatch<Msg>) -> Void
    let runtimeQueue: DispatchQueue
    let renderQueue: DispatchQueue
    let effectQueue: DispatchQueue
    
    private var currentState: Model
    
    init(
        initial: @escaping () -> (Model, Effect<Msg>),
        update: @escaping (Msg, Model) -> (Model, Effect<Msg>?),
        view: @escaping (Model) -> Props,
        render: @escaping (Props, Dispatch<Msg>) -> Void,
        runtimeQueue: DispatchQueue = _runtimeQueue,
        renderQueue: DispatchQueue = _renderQueue,
        effectQueue: DispatchQueue = _effectQueue)
    {
        self.update = update
        self.view = view
        self.render = render
        self.runtimeQueue = runtimeQueue
        self.renderQueue = renderQueue
        self.effectQueue = effectQueue
        
        let initial = initial()
        currentState = initial.0
        runtimeQueue.async { [self] in
            step(next: initial)
        }
    }
    
    private func dispatch(msg: Msg) {
        runtimeQueue.async { [self] in
            step(next: update(msg, currentState))
        }
    }
    
    private func step(next: (Model, Effect<Msg>?)) {
        let (state, effect) = next
        let props = view(state)
        currentState = state
        renderQueue.async { [self] in
            render(props, dispatch)
        }
        effect.map { effect in
            effectQueue.async { [self] in
                effect(dispatch)
            }
        }
    }
}
