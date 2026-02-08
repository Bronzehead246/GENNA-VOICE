                                                                                
 ```python                                                                      
   #!/data/data/com.termux/files/usr/bin/env python3                            
   """                                                                          
   GENNA Voice Assistant for Termux/Android                                     
   Fully offline, local voice AI                                                
   """                                                                          
                                                                                
   import os                                                                    
   import sys                                                                   
   import time                                                                  
   import tempfile                                                              
   import subprocess                                                            
                                                                                
   # Configuration                                                              
   WAKE_WORDS = ["hey genna", "genna", "okay genna"]                            
   SAMPLE_RATE = 16000                                                          
   CHUNK_DURATION = 3                                                           
                                                                                
   # Paths                                                                      
   HOME = os.environ.get('HOME', '/data/data/com.termux/files/home')            
   PIPER_MODEL = f"{HOME}/.local/share/piper/en_US-lessac-medium.onnx"          
                                                                                
   class GENNAVoiceTermux:                                                      
       def __init__(self):                                                      
           print("Loading Whisper...")                                          
           from faster_whisper import WhisperModel                              
           self.whisper = WhisperModel("base", device="cpu",                    
 compute_type="int8")                                                           
           print("Whisper ready!")                                              
           self.check_microphone()                                              
                                                                                
       def check_microphone(self):                                              
           result = subprocess.run(['which', 'termux-microphone'],              
 capture_output=True)                                                           
           if result.returncode != 0:                                           
               print("\n[!] termux-microphone not found!")                      
               print("Install it with: pkg install termux-api")                 
               print("And install Termux:API app from F-Droid\n")               
               sys.exit(1)                                                      
                                                                                
       def record_audio(self, duration=3, output_file=None):                    
           if output_file is None:                                              
               output_file = tempfile.mktemp(suffix='.wav')                     
                                                                                
           print(f"🎤 Recording for {duration} seconds...")                     
           subprocess.run([                                                     
               'termux-microphone', '-r', str(SAMPLE_RATE),                     
               '-l', str(duration), '-f', output_file                           
           ], capture_output=True)                                              
           return output_file                                                   
                                                                                
       def transcribe(self, audio_file):                                        
           segments, _ = self.whisper.transcribe(audio_file, language="en")     
           text = " ".join([segment.text for segment in segments]).strip()      
           return text.lower()                                                  
                                                                                
       def speak(self, text):                                                   
           print(f"🔊 GENNA: {text}")                                           
           with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as     
 tmp:                                                                           
               wav_file = tmp.name                                              
                                                                                
           try:                                                                 
               piper_cmd = [                                                    
                   sys.executable, '-m', 'piper',                               
                   '--model', PIPER_MODEL, '--output_file', wav_file            
               ]                                                                
               result = subprocess.run(piper_cmd, input=text.encode(),          
                                      capture_output=True, timeout=30)          
                                                                                
               if result.returncode == 0 and os.path.exists(wav_file):          
                   subprocess.run(['termux-media-player', 'play', wav_file])    
                   time.sleep(0.5)                                              
                   while self.is_playing():                                     
                       time.sleep(0.5)                                          
           except Exception as e:                                               
               print(f"Speak error: {e}")                                       
           finally:                                                             
               try: os.unlink(wav_file)                                         
               except: pass                                                     
                                                                                
       def is_playing(self):                                                    
           result = subprocess.run(['termux-media-player'],                     
                                  capture_output=True, text=True)               
           return 'Playing' in result.stdout                                    
                                                                                
       def send_to_openclaw(self, text):                                        
           responses = {                                                        
               "hello": "Hey Cally! I'm here and listening on your phone.",     
               "hey": "Yes Cally? What do you need?",                           
               "hi": "Hello! GENNA is ready on your phone.",                    
               "how are you": "Running smooth on Termux, Cally. Ready to        
 help.",                                                                        
               "what can you do": "I can search, manage files, run commands,    
 and automate tasks.",                                                          
               "test": "Voice system is working perfectly, Cally.",             
               "who are you": "I'm GENNA, your automation AI companion.",       
               "shutdown": "Shutting down. Goodbye Cally!",                     
               "exit": "Goodbye Cally!",                                        
               "quit": "See you soon, Cally!",                                  
           }                                                                    
                                                                                
           if text in responses:                                                
               return responses[text]                                           
           for key, response in responses.items():                              
               if key in text:                                                  
                   return response                                              
           return f"You said: {text}. I'm running locally on your phone."       
                                                                                
       def listen_for_wake(self):                                               
           print("\n" + "="*50)                                                 
           print("  GENNA Voice Assistant - Running on Phone")                  
           print("="*50)                                                        
           print("Say 'Hey GENNA' to wake me up")                               
           print("Say 'shutdown', 'exit', or 'quit' to stop")                   
           print("="*50 + "\n")                                                 
                                                                                
           self.speak("GENNA is ready on your phone, Cally.")                   
                                                                                
           running = True                                                       
           while running:                                                       
               try:                                                             
                   with tempfile.NamedTemporaryFile(suffix='.wav',              
 delete=False) as tmp:                                                          
                       audio_file = self.record_audio(CHUNK_DURATION, tmp.name) 
                                                                                
                   text = self.transcribe(audio_file)                           
                                                                                
                   try: os.unlink(audio_file)                                   
                   except: pass                                                 
                                                                                
                   if text:                                                     
                       print(f"Heard: {text}")                                  
                                                                                
                       if any(wake in text for wake in WAKE_WORDS):             
                           print("✨ Wake word detected!")                      
                           running = self.handle_command()                      
                       elif any(cmd in text for cmd in ["shutdown", "exit",     
 "quit"]):                                                                      
                           self.speak("Goodbye Cally!")                         
                           running = False                                      
                                                                                
               except KeyboardInterrupt:                                        
                   print("\n\nInterrupted")                                     
                   self.speak("Shutting down. Goodbye!")                        
                   break                                                        
               except Exception as e:                                           
                   print(f"Error: {e}")                                         
                   time.sleep(1)                                                
                                                                                
           print("\nGENNA Voice Assistant stopped.")                            
                                                                                
       def handle_command(self):                                                
           self.speak("Yes, Cally?")                                            
                                                                                
           with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as     
 tmp:                                                                           
               audio_file = self.record_audio(5, tmp.name)                      
                                                                                
           command = self.transcribe(audio_file)                                
                                                                                
           try: os.unlink(audio_file)                                           
           except: pass                                                         
                                                                                
           print(f"Command: {command}")                                         
                                                                                
           if command:                                                          
               if any(cmd in command for cmd in ["shutdown", "exit", "quit",    
 "stop"]):                                                                      
                   self.speak("Shutting down. Goodbye Cally!")                  
                   return False                                                 
                                                                                
               response = self.send_to_openclaw(command)                        
               self.speak(response)                                             
           else:                                                                
               self.speak("I didn't catch that. Could you repeat?")             
                                                                                
           return True                                                          
                                                                                
   if __name__ == "__main__":                                                   
       try:                                                                     
           assistant = GENNAVoiceTermux()                                       
           assistant.listen_for_wake()                                          
       except Exception as e:                                                   
           print(f"Fatal error: {e}")                                           
           sys.exit(1)  
