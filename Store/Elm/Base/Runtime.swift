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

protocol ModelViewable {
    associatedtype Props
    
    var buildProps: Props { get }
}

class Runtime<Model: ModelViewable, Msg> {
    typealias Initial = () -> (Model, Effect<Msg>?)
    typealias Update = (Msg, Model) -> (Model, Effect<Msg>?)
    typealias Render = (Model.Props, @escaping Dispatch<Msg>) -> Void
    
    let update: (Msg, Model) -> (Model, Effect<Msg>?)
    let render: Render
    let runtimeQueue: DispatchQueue
    let renderQueue: DispatchQueue
    let effectQueue: DispatchQueue
    
    private var currentState: Model
    
    init(
        initial: @escaping Initial,
        update: @escaping Update,
        render: @escaping Render,
        runtimeQueue: DispatchQueue = _runtimeQueue,
        renderQueue: DispatchQueue = _renderQueue,
        effectQueue: DispatchQueue = _effectQueue)
    {
        self.update = update
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
        let props = state.buildProps
        currentState = state
        renderQueue.async { [self] in
            render(props) { [weak self] in
                self?.dispatch(msg: $0)
            }
        }
        effect.map { effect in
            effectQueue.async { [self] in
                effect(dispatch)
            }
        }
    }
}
