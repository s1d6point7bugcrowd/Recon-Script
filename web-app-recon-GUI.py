import tkinter as tk
from tkinter import ttk, messagebox
import subprocess
import threading
import os
import signal
import re
import time

class Web App Recon:
    def __init__(self, root):
        self.root = root
        root.title("Vulnerability Scanner")
        root.geometry("800x600")

        # Initialize the process attribute
        self.process = None
        self.last_voice_notification = ""

        # Create a style
        self.style = ttk.Style()
        self.style.configure("TButton", font=("Helvetica", 10))
        self.style.configure("TLabel", font=("Helvetica", 12))
        self.style.configure("TEntry", font=("Helvetica", 12))

        # Create a main frame
        main_frame = ttk.Frame(root, padding="10 10 10 10")
        main_frame.pack(fill=tk.BOTH, expand=True)

        # Add a scrollbar to the main frame
        canvas = tk.Canvas(main_frame)
        scrollbar = ttk.Scrollbar(main_frame, orient="vertical", command=canvas.yview)
        scrollable_frame = ttk.Frame(canvas)

        scrollable_frame.bind(
            "<Configure>",
            lambda e: canvas.configure(
                scrollregion=canvas.bbox("all")
            )
        )

        canvas.create_window((0, 0), window=scrollable_frame, anchor="nw")
        canvas.configure(yscrollcommand=scrollbar.set)

        canvas.pack(side="left", fill="both", expand=True)
        scrollbar.pack(side="right", fill="y")

        # Header
        header_label = ttk.Label(scrollable_frame, text="Vulnerability Scanner", font=("Helvetica", 16, "bold"))
        header_label.pack(pady=10)

        # Enable Voice Announcements
        self.enable_voice_var = tk.StringVar(value="n")
        ttk.Label(scrollable_frame, text="Enable Voice Announcements:").pack(anchor=tk.W, padx=20, pady=5)
        self.enable_voice_check = ttk.Checkbutton(scrollable_frame, text="Enable", variable=self.enable_voice_var, onvalue="y", offvalue="n")
        self.enable_voice_check.pack(anchor=tk.W, padx=20)

        # Data Storage
        self.store_data_var = tk.StringVar(value="n")
        ttk.Label(scrollable_frame, text="Store Data Permanently:").pack(anchor=tk.W, padx=20, pady=5)
        self.store_data_check = ttk.Checkbutton(scrollable_frame, text="Enable", variable=self.store_data_var, onvalue="y", offvalue="n")
        self.store_data_check.pack(anchor=tk.W, padx=20)

        # Use Proxychains
        self.use_proxychains_var = tk.StringVar(value="n")
        ttk.Label(scrollable_frame, text="Use Proxychains:").pack(anchor=tk.W, padx=20, pady=5)
        self.use_proxychains_check = ttk.Checkbutton(scrollable_frame, text="Enable", variable=self.use_proxychains_var, onvalue="y", offvalue="n")
        self.use_proxychains_check.pack(anchor=tk.W, padx=20)

        # Scan Type
        self.scan_type_var = tk.StringVar(value="1")
        ttk.Label(scrollable_frame, text="Scan Type:").pack(anchor=tk.W, padx=20, pady=5)
        self.scan_type_radio1 = ttk.Radiobutton(scrollable_frame, text="Domain", variable=self.scan_type_var, value="1")
        self.scan_type_radio2 = ttk.Radiobutton(scrollable_frame, text="Single URL", variable=self.scan_type_var, value="2")
        self.scan_type_radio1.pack(anchor=tk.W, padx=40)
        self.scan_type_radio2.pack(anchor=tk.W, padx=40)

        # Out-of-Scope Patterns
        ttk.Label(scrollable_frame, text="Out-of-Scope Patterns (comma-separated):").pack(anchor=tk.W, padx=20, pady=5)
        self.oos_patterns_entry = ttk.Entry(scrollable_frame, width=50)
        self.oos_patterns_entry.pack(anchor=tk.W, padx=20)
        self.add_context_menu(self.oos_patterns_entry)

        # Bug Bounty Program Name
        ttk.Label(scrollable_frame, text="Bug Bounty Program Name:").pack(anchor=tk.W, padx=20, pady=5)
        self.program_name_entry = ttk.Entry(scrollable_frame, width=50)
        self.program_name_entry.pack(anchor=tk.W, padx=20)
        self.add_context_menu(self.program_name_entry)

        # Nuclei Template Paths
        ttk.Label(scrollable_frame, text="Nuclei Template Paths (comma-separated):").pack(anchor=tk.W, padx=20, pady=5)
        self.template_paths_entry = ttk.Entry(scrollable_frame, width=50)
        self.template_paths_entry.pack(anchor=tk.W, padx=20)
        self.add_context_menu(self.template_paths_entry)

        # Nuclei Template Tags
        ttk.Label(scrollable_frame, text="Nuclei Template Tags (comma-separated):").pack(anchor=tk.W, padx=20, pady=5)
        self.template_tags_entry = ttk.Entry(scrollable_frame, width=50)
        self.template_tags_entry.pack(anchor=tk.W, padx=20)
        self.add_context_menu(self.template_tags_entry)

        # Nuclei Severity Levels
        ttk.Label(scrollable_frame, text="Nuclei Severity Levels (comma-separated):").pack(anchor=tk.W, padx=20, pady=5)
        self.severity_levels_entry = ttk.Entry(scrollable_frame, width=50)
        self.severity_levels_entry.pack(anchor=tk.W, padx=20)
        self.add_context_menu(self.severity_levels_entry)

        # Target Entry
        self.target_label = ttk.Label(scrollable_frame, text="Enter the Target Domain or URL:")
        self.target_label.pack(anchor=tk.W, padx=20, pady=5)
        self.target_entry = ttk.Entry(scrollable_frame, width=50)
        self.target_entry.pack(anchor=tk.W, padx=20)
        self.add_context_menu(self.target_entry)

        # Start Scan Button
        self.start_button = ttk.Button(scrollable_frame, text="Start Scan", command=self.start_scan_thread)
        self.start_button.pack(pady=5)

        # Abort Scan Button
        self.abort_button = ttk.Button(scrollable_frame, text="Abort Scan", command=self.abort_scan)
        self.abort_button.pack(pady=5)

        # Console Output with Scrollbar
        console_frame = ttk.Frame(scrollable_frame)
        console_frame.pack(padx=20, pady=10, fill=tk.BOTH, expand=True)
        self.console_output = tk.Text(console_frame, height=20, state='normal', bg='black', fg='white')
        self.console_output.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        console_scrollbar = ttk.Scrollbar(console_frame, orient="vertical", command=self.console_output.yview)
        self.console_output.configure(yscrollcommand=console_scrollbar.set)
        console_scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

        # Configure tags for colored text
        self.console_output.tag_config('info', foreground='cyan')
        self.console_output.tag_config('error', foreground='red')
        self.console_output.tag_config('normal', foreground='white')
        self.console_output.tag_config('highlight', foreground='yellow')

        # Add context menu for copying text
        self.add_context_menu(self.console_output)

    def add_context_menu(self, widget):
        context_menu = tk.Menu(widget, tearoff=0)
        context_menu.add_command(label="Cut", command=lambda: widget.event_generate("<<Cut>>"))
        context_menu.add_command(label="Copy", command=lambda: widget.event_generate("<<Copy>>"))
        context_menu.add_command(label="Paste", command=lambda: widget.event_generate("<<Paste>>"))
        context_menu.add_command(label="Select All", command=lambda: widget.event_generate("<<SelectAll>>"))

        def show_context_menu(event):
            context_menu.tk_popup(event.x_root, event.y_root)

        widget.bind("<Button-3>", show_context_menu)

    def voice_notification(self, message):
        if self.enable_voice_var.get() == "y":
            if message != self.last_voice_notification:
                self.last_voice_notification = message
                subprocess.call(['espeak', '-s', '140', '-v', 'en+f3', message])
                time.sleep(0.5)  # Short delay to prevent echo

    def start_scan_thread(self):
        threading.Thread(target=self.start_scan).start()

    def start_scan(self):
        enable_voice = self.enable_voice_var.get()
        store_data = self.store_data_var.get()
        use_proxychains = self.use_proxychains_var.get()
        scan_type = self.scan_type_var.get()
        oos_patterns = self.oos_patterns_entry.get()
        program_name = self.program_name_entry.get()
        template_paths = self.template_paths_entry.get()
        template_tags = self.template_tags_entry.get()
        severity_levels = self.severity_levels_entry.get()
        target = self.target_entry.get()

        # Prepare environment variables
        env_vars = os.environ.copy()
        env_vars.update({
            "ENABLE_VOICE": enable_voice,
            "STORE_PERMANENTLY": store_data,
            "USE_PROXYCHAINS": use_proxychains,
            "SCAN_TYPE": scan_type,
            "OOS_INPUT": oos_patterns,
            "PROGRAM_NAME": program_name,
            "TEMPLATE_PATHS": template_paths,
            "TEMPLATE_TAGS": template_tags,
            "SEVERITY_LEVELS": severity_levels,
            "TARGET": target,
        })

        # Prepare command
        command = ["/bin/bash", "/home/kali/web-app-recon.sh"]

        # Simulate inputs to the script
        script_input = f"{enable_voice}\n{store_data}\n{use_proxychains}\n{scan_type}\n{oos_patterns}\n{program_name}\n{template_paths}\n{template_tags}\n{severity_levels}\n{target}\n"

        self.console_output.config(state='normal')
        self.console_output.delete(1.0, tk.END)  # Clear previous output

        # Run the command
        self.process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, stdin=subprocess.PIPE, env=env_vars, text=True, bufsize=1, universal_newlines=True)

        def update_output(stream, is_error=False):
            ansi_escape = re.compile(r'\x1B[@-_][0-?]*[ -/]*[@-~]')  # Regular expression to match ANSI escape sequences
            for line in iter(stream.readline, ''):
                cleaned_line = ansi_escape.sub('', line)  # Remove ANSI escape sequences
                tag = 'normal'
                # Filter out unwanted messages
                if not any(substring in cleaned_line for substring in [
                    "Do you want", "Enter", "Debug", "coded by", "Running nuclei command:", "No Nuclei template paths provided"
                ]):
                    if "Running nuclei" in cleaned_line or "results" in cleaned_line or "completed" in cleaned_line:
                        tag = 'highlight'
                        self.voice_notification(cleaned_line.strip())
                    elif "ERROR:" in cleaned_line:
                        tag = 'error'
                    elif re.search(r'\[INF\]', cleaned_line):
                        tag = 'info'
                    if not cleaned_line.startswith("ERROR:"):
                        self.console_output.insert(tk.END, cleaned_line, tag)
                self.console_output.see(tk.END)
            stream.close()

        stdout_thread = threading.Thread(target=update_output, args=(self.process.stdout,))
        stderr_thread = threading.Thread(target=update_output, args=(self.process.stderr, True))

        stdout_thread.start()
        stderr_thread.start()

        # Provide the inputs to the script
        self.process.stdin.write(script_input)
        self.process.stdin.close()

        stdout_thread.join()
        stderr_thread.join()

        self.process.wait()
        self.console_output.config(state='disabled')

    def abort_scan(self):
        if self.process:
            self.process.send_signal(signal.SIGINT)  # Send SIGINT (Ctrl+C) to the process
            try:
                self.process.wait(timeout=5)  # Wait for the process to terminate
            except subprocess.TimeoutExpired:
                self.process.terminate()  # Forcefully terminate if it does not exit
                self.process.wait(timeout=5)
            self.console_output.insert(tk.END, "\nScan aborted by user.\n", 'error')
            self.console_output.see(tk.END)
            self.console_output.config(state='disabled')
            self.process = None

if __name__ == "__main__":
    root = tk.Tk()
    app = VulnerabilityScannerApp(root)
    root.mainloop()
