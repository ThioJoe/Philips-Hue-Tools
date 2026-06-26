
## Tools

### `HueBulbReplacer.html:`
- Local browser-based tool for replacing a Philips Hue bulb with a new one, and inherting all its properties

### `Force-Check-Bridge-Updates.ps1:`
- PowerShell script to force your bridge to check for new updates, then lets you initiate the install if an update is found.
- You can run it by opening Windows PowerShell to the folder containing the script and running this command:
  ```powershell
  Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force; .\Force-Check-Bridge-Updates.ps1
  ```


## How to Get an API Key

API Keys are generated locally on your bridge. Here's how:

 1. Find your bridge's local IP address in the Hue app:
    - Settings > Bridges > Select your bridge > Look at the "IP-address" field.
    <p align="center"> <img width="350" src="https://github.com/user-attachments/assets/e707e05d-eb44-42cd-b20e-79d19ff7edd0" /></p>

2. After finding the IP, go to this address in your browser, filling in the IP of the bridge:
    ```
    https://WHATEVER-IP/debug/clip.html
    ```
    
    - You might get a "insecure connection" warning, just ignore that and continue
    - You should see a page like this:
  <p align="center"> <img width="350" src="https://github.com/user-attachments/assets/4884ac07-1a5c-4aa8-8e03-50d75c721a49" /> </p>

3. In the "URL" field, put `/api/`
   <p align="center"> <img width="350" src="https://github.com/user-attachments/assets/813dbed4-ad67-4105-8af5-7c85990499e3" /></p>

5. In the "Message Body" field, put:
   ```
   {"devicetype":"my_hue_app#my_api_key"}
   ```
   
    <p align="center"> <img width="350" src="https://github.com/user-attachments/assets/5097c656-67b2-4edd-a01f-41f65b8b1b11" /></p>


6. **IMPORTANT:** Go physically press the link button on your bridge (the big circle button)
    - You'll then have 30 seconds to complete the next step, or else it will return an error and you'd have to press the button again.
  
8. Click "POST":

   <p align="center"> <img width="350" src="https://github.com/user-attachments/assets/62d98eb8-906a-4feb-b8f5-2dec17aeb586" /></p>

9. The "Command Response" box should hopefully say "success"
     - **The long string of characters labelled `username` is your API Key.**
       - (The quotation marks are NOT part of the key)
    - Be sure to store the key somewhere safe you won't lose it, or else you'll have to generate a new one, and the old one will still persist. You won't be shown it again.
    - Don't share the key with anyone (I edited the string in the example screenshot so it's not real)
   
<p align="center">
<img width="500" src="https://github.com/user-attachments/assets/37616e73-fb3f-4afe-bb0d-dbc6bec61212" />
</p>

