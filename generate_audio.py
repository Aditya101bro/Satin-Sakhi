#!/usr/bin/env python3
from gtts import gTTS
import os, sys, time

OUTPUT_DIR = os.path.join("assets","audio")
PROMPTS = {
    "blur":"Thoda blur aa raha hai, haath rok ke rakho",
    "very_blur":"Photo bilkul dhundhli hai, phone ko stable karo",
    "low_light":"Roshni kam hai, kisi ujale jagah le jaao",
    "glare":"Reflection aa rahi hai, thoda angle badlo",
    "too_bright":"Zyada roshni hai, direct light se door ho jaao",
    "too_far":"Thoda paas lao, document chota dikh raha hai",
    "too_close":"Thoda door karo, poora document frame mein nahi aa raha",
    "tilt":"Card seedha rakho, thoda ghuma hua hai",
    "not_aadhaar":"Yeh Aadhaar card nahi lag raha, sahi document dikhaayen",
    "not_pan":"Yeh PAN card nahi lag raha, sahi document dikhaayen",
    "not_passbook":"Yeh passbook nahi lag rahi, sahi document dikhaayen",
    "not_voter":"Yeh voter ID nahi lag rahi, sahi document dikhaayen",
    "not_license":"Yeh driving licence nahi lag raha, sahi document dikhaayen",
    "doc_good":"Ab theek hai",
    "doc_captured":"Document capture ho gaya, bahut accha",
    "place_aadhaar":"Aadhaar card ko neeche rakhe aur camera uske upar laayen",
    "place_pan":"PAN card ko neeche rakhe aur camera uske upar laayen",
    "place_passbook":"Passbook khol ke neeche rakhe aur camera uske upar laayen",
    "selfie_instruction":"Camera ko chehre ke saamne rakhen aur seedha dekhein",
    "no_face":"Chehra frame mein laayen",
    "face_too_far":"Thoda paas aao, poora chehra nahi dikh raha",
    "face_too_close":"Thoda door ho jao",
    "face_left":"Thoda daayein ghoomein",
    "face_right":"Thoda baayein ghoomein",
    "face_up":"Thoda upar karo",
    "face_down":"Thoda neeche jhukao",
    "eyes_closed":"Aankhein khuli rakhen",
    "multiple_faces":"Sirf ek chehra frame mein hona chahiye",
    "blink_prompt":"Ek baar aankhein jhapkaayen",
    "face_good":"Bilkul sahi, ek second rukein",
    "face_captured":"Tasveer le li gayi, shukriya",
}
os.makedirs(OUTPUT_DIR, exist_ok=True)
total,ok,failed=len(PROMPTS),0,[]
for i,(k,t) in enumerate(PROMPTS.items(),1):
    path=os.path.join(OUTPUT_DIR,f"{k}.mp3")
    if os.path.exists(path) and os.path.getsize(path)>1000: print(f"[{i:02}/{total}] SKIP {k}"); ok+=1; continue
    try: gTTS(text=t,lang='hi',slow=False).save(path); print(f"[{i:02}/{total}]  OK  {k}"); ok+=1; time.sleep(0.3)
    except Exception as e: print(f"[{i:02}/{total}] FAIL {k}: {e}"); failed.append(k)
print(f"Done {ok}/{total}"); 
if failed: print("Failed:",failed)
