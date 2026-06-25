import React, { useEffect } from "react";
import "./ActionNotification.css";

const ActionNotification = ({
    open,
    type = "success", // success | error | warning | info
    message = "",
    onClose,
    duration = 2200,
}) => {
    useEffect(() => {   
        if (!open) return;

        const timer = setTimeout(() => {
            onClose?.();
        }, duration);

        return () => clearTimeout(timer);
    }, [open, duration, onClose]);

    if (!open) return null;

    const iconMap = {
        success: "✓",
        error: "✕",
        warning: "!",
        info: "i",
    };

    return (
        <div className="action-notification-overlay">
            <div className={`action-notification-box ${type}`}>
                <div className={`action-notification-icon ${type}`}>
                    {iconMap[type] || "i"}
                </div>
                <p className="action-notification-message">{message}</p>
            </div>
        </div>
    );
};

export default ActionNotification;