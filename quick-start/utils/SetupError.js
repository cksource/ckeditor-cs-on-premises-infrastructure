class SetupError extends Error {  
   constructor (message, stepMessage) {
     super(message);
 
     this.name = this.constructor.name;
     Error.captureStackTrace(this, this.constructor);

     this.stepMessage = stepMessage;
   }
 }
 
 module.exports = SetupError  