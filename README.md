# 🗂️ sim-contract — A Decentralized Smart Messaging Contract on Stacks

 Overview
The **sim-contract** (Simple Message Contract) is a decentralized smart contract built with **Clarity** for the **Stacks blockchain**.  
It allows users to **write, update, delete, and view** on-chain messages securely — all while maintaining transparency and immutability.

This project demonstrates key concepts of Clarity smart contract development including:
- On-chain data persistence using `define-map`
- Admin control with access restrictions
- Event logging for blockchain observability
- List tracking and safe data handling

Built for developers who are learning **Clarity** and **Clarinet**, and perfect for the **Code-for-STX** monthly submission.

---

 Features

-  **Write & Update Messages:** Each user can create or edit a personal on-chain message.  
-  **Delete Messages:** Remove your existing message entry anytime.  
-  **Read Messages:** Retrieve your message content and timestamp.  
-  **Signer Tracking:** Keeps a list of unique message authors.  
-  **Admin Control:** Admin can reset stats or transfer admin rights.  
-  **Events:** Emits events on write, update, delete, and admin actions.  
-  **Fully Testable:** Designed to work perfectly with Clarinet.

---

 Contract Structure

| Function | Type | Description |
|-----------|------|-------------|
| `write-message` | Public | Allows user to create a new on-chain message |
| `update-message` | Public | Updates a user’s existing message |
| `delete-message` | Public | Removes a user’s stored message |
| `get-message` | Read-only | Retrieves a message and its timestamp |
| `has-message?` | Read-only | Checks if a user has a stored message |
| `list-signers` | Read-only | Returns list of all message authors |
| `get-total-messages` | Read-only | Displays the total message count |
| `get-stats` | Read-only | Returns general contract statistics |
| `transfer-admin` | Public | Transfers admin rights to another principal |
| `admin-reset` | Public | Resets contract statistics (admin only) |
| `get-admin` | Read-only | Returns current admin principal |

---

 Setup Instructions

Create a new Clarinet project
```bash
clarinet new sim-contract
cd sim-contract
