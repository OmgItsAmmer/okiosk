# Running LLM for Backend

## 1. Start Local LLM Server
You need to run the local LLM server before starting the backend.

Execute the following command in your terminal:

```powershell
.\llama.cpp\build\bin\Release\llama-server.exe `
  -m .\llama.cpp\custom_models\mistral-7b-instruct-v0.2.Q4_K_M.gguf`
  -t 8 `
  --port 8080 `
  --ctx-size 2048 `
  --grammar-file .\llama.cpp\custom_models\actions.gbnf
```



This starts an OpenAI-compatible server on `http://localhost:8080`.

## 2. Configure Environment Variables (.env)
The backend is now configured to use `LLM_API_URL` instead of `GEMINI_API_KEY`.

Add or update the following line in your `kks_online_backend/.env` file:

```env
LLM_API_URL=http://localhost:8080/v1/chat/completions
```

*Note: If you don't set this variable, the backend defaults to `http://localhost:8080/v1/chat/completions`, which matches the default llama-server setup.*

**Remove or comment out `GEMINI_API_KEY` as it is no longer used.**

## 3. Run the Backend
Start the backend as usual:

```powershell
cd kks_online_backend
cargo run
```

The backend will now send AI commands to your local Mistral model.



.\llama.cpp\build\bin\Release\llama-server.exe `
  -m ".\llama.cpp\custom_models\mistral-7b-instruct-v0.2.Q4_K_M.gguf" `
  -t 8 `
  --port 8080 `
  --ctx-size 2048 `
  --grammar-file ".\llama.cpp\custom_models\actions.gbnf"