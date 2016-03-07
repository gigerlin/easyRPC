###
  @author Gilles Gerlinger
  Copyright 2015. All rights reserved.
###

module.exports = class Promise
  status: 0 # 0: pending, 1: resolved, 2: rejected
  constructor: (ready) ->
    # console.log 'using own Promise'
    @_chain = []
    ready(
      => @resolve arguments... # set resolve
      => @reject  arguments... # set reject
    ) if ready

  then: (resolve) -> @_chain.push type:1, func:resolve; @
  catch: (reject) -> @_chain.push type:2, func:reject; @

  resolve: -> @_process 1, arguments...
  reject:  -> @_process 2, arguments...

  _process: (type, args...) ->
    if next = @_chain.shift()
      if next.type is type
        try
          if (rst = next.func args...) instanceof Promise # chain with outer promise
            @status = 0
            rst
            .then (param) => @resolve param
            .catch (param) => @reject param
          else
            @status = type 
            @resolve rst # Promise rejections skip forward to the next "then"
        catch evt then @reject evt
      else if type is 1 then @resolve args... else @reject args...

