module.exports = class Employee
  getProfile: (name) -> 
    console.log 'getProfile of', name
    new Promise (resolve, reject) ->
      setTimeout (-> resolve age:32, email:'john@acme.com'), 3000 